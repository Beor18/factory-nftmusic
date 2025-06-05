// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title RevenueShare
 * @notice Manages revenue distribution for NFT collections with direct payment splits and resale royalties
 * @dev Implements direct payment distribution with inheritance tracking for remixes/playlists
 * @dev Supports both native tokens (ETH) and ERC20 tokens (USDC, DAI, etc.)
 */
contract RevenueShare is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev Custom errors for gas efficiency
    error NotOwner();
    error NoShares();
    error InvalidAddress();
    error ZeroPercentage();
    error InvalidTotal(uint96 total);
    error TransferFailed();
    error EmptyName();
    error InvalidTokenId();
    error InvalidAmount();

    struct Share {
        address account;
        uint96 percentage; // base 10000 = 100%
    }

    address public immutable owner;
    string public name;
    string public description;

    mapping(address => mapping(uint256 => Share[])) public mintSplits;
    mapping(address => mapping(uint256 => Share[])) public resaleRoyalties;
    mapping(uint256 => address[]) public inheritedFrom; // tokenId (remix or playlist) => source token addresses

    /// @dev Collection-wide defaults (when tokenId = 0, applies to whole collection)
    mapping(address => Share[]) public collectionMintSplits;
    mapping(address => Share[]) public collectionResaleRoyalties;

    /// @dev Cascade settings for remixes/playlists
    mapping(uint256 => uint96) public cascadePercentage; // Percentage that goes to original sources

    /// @dev Events for comprehensive state change tracking
    event MintSplitsSet(
        address indexed collection,
        uint256 indexed tokenId,
        Share[] shares
    );

    event ResaleRoyaltiesSet(
        address indexed collection,
        uint256 indexed tokenId,
        Share[] shares
    );

    event InheritanceSet(uint256 indexed tokenId, address[] sources);

    event PaymentDistributed(
        address indexed collection,
        uint256 indexed tokenId,
        uint256 amount
    );

    event ERC20PaymentDistributed(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed token,
        uint256 amount
    );

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /**
     * @notice Creates a new RevenueShare contract
     * @param _owner Address that will own this revenue share contract
     * @param _name Name of the revenue share arrangement
     * @param _description Description of the revenue share arrangement
     */
    constructor(
        address _owner,
        string memory _name,
        string memory _description
    ) {
        if (_owner == address(0)) revert InvalidAddress();
        if (bytes(_name).length == 0) revert EmptyName();

        owner = _owner;
        name = _name;
        description = _description;
    }

    /**
     * @notice Sets the mint revenue splits for a specific NFT
     * @param collection The NFT collection address
     * @param tokenId The token ID
     * @param shares Array of revenue shares that must total 10000 (100%)
     */
    function setMintSplits(
        address collection,
        uint256 tokenId,
        Share[] memory shares
    ) external onlyOwner {
        if (shares.length == 0) revert NoShares();
        if (collection == address(0)) revert InvalidAddress();

        delete mintSplits[collection][tokenId];
        uint96 total;

        for (uint i = 0; i < shares.length; i++) {
            if (shares[i].account == address(0)) revert InvalidAddress();
            if (shares[i].percentage == 0) revert ZeroPercentage();
            total += shares[i].percentage;
            mintSplits[collection][tokenId].push(shares[i]);
        }

        if (total != 10000) revert InvalidTotal(total);

        emit MintSplitsSet(collection, tokenId, shares);
    }

    /**
     * @notice Sets the resale royalty splits for a specific NFT
     * @param collection The NFT collection address
     * @param tokenId The token ID
     * @param shares Array of royalty shares that must total 10000 (100%)
     */
    function setResaleRoyalties(
        address collection,
        uint256 tokenId,
        Share[] memory shares
    ) external onlyOwner {
        if (shares.length == 0) revert NoShares();
        if (collection == address(0)) revert InvalidAddress();

        delete resaleRoyalties[collection][tokenId];
        uint96 total;

        for (uint i = 0; i < shares.length; i++) {
            if (shares[i].account == address(0)) revert InvalidAddress();
            if (shares[i].percentage == 0) revert ZeroPercentage();
            total += shares[i].percentage;
            resaleRoyalties[collection][tokenId].push(shares[i]);
        }

        if (total != 10000) revert InvalidTotal(total);

        emit ResaleRoyaltiesSet(collection, tokenId, shares);
    }

    /**
     * @notice Sets the inheritance sources for remix/playlist tokens
     * @param tokenId The remix/playlist token ID
     * @param sources Array of source token addresses this token inherits from
     */
    function setInheritance(
        uint256 tokenId,
        address[] memory sources
    ) external onlyOwner {
        inheritedFrom[tokenId] = sources;
        emit InheritanceSet(tokenId, sources);
    }

    /**
     * @notice Sets mint splits for an entire collection (default for all tokens)
     * @param collection The NFT collection address
     * @param shares Array of revenue shares that must total 10000 (100%)
     */
    function setCollectionMintSplits(
        address collection,
        Share[] memory shares
    ) external onlyOwner {
        if (shares.length == 0) revert NoShares();
        if (collection == address(0)) revert InvalidAddress();

        delete collectionMintSplits[collection];
        uint96 total;

        for (uint i = 0; i < shares.length; i++) {
            if (shares[i].account == address(0)) revert InvalidAddress();
            if (shares[i].percentage == 0) revert ZeroPercentage();
            total += shares[i].percentage;
            collectionMintSplits[collection].push(shares[i]);
        }

        if (total != 10000) revert InvalidTotal(total);

        emit MintSplitsSet(collection, 0, shares); // tokenId 0 = collection-wide
    }

    /**
     * @notice Sets resale royalties for an entire collection (default for all tokens)
     * @param collection The NFT collection address
     * @param shares Array of royalty shares that must total 10000 (100%)
     */
    function setCollectionResaleRoyalties(
        address collection,
        Share[] memory shares
    ) external onlyOwner {
        if (shares.length == 0) revert NoShares();
        if (collection == address(0)) revert InvalidAddress();

        delete collectionResaleRoyalties[collection];
        uint96 total;

        for (uint i = 0; i < shares.length; i++) {
            if (shares[i].account == address(0)) revert InvalidAddress();
            if (shares[i].percentage == 0) revert ZeroPercentage();
            total += shares[i].percentage;
            collectionResaleRoyalties[collection].push(shares[i]);
        }

        if (total != 10000) revert InvalidTotal(total);

        emit ResaleRoyaltiesSet(collection, 0, shares); // tokenId 0 = collection-wide
    }

    /**
     * @notice Sets cascade percentage for remix/playlist tokens
     * @param tokenId The remix/playlist token ID
     * @param percentage Percentage that goes to original sources (base 10000)
     */
    function setCascadePercentage(
        uint256 tokenId,
        uint96 percentage
    ) external onlyOwner {
        if (percentage > 10000) revert InvalidTotal(percentage);
        cascadePercentage[tokenId] = percentage;
    }

    /**
     * @notice Distributes mint payment with direct transfers to recipients (ETH)
     * @param collection The NFT collection address
     * @param tokenId The token ID being minted
     */
    function distributeMintPayment(
        address collection,
        uint256 tokenId
    ) external payable nonReentrant {
        Share[] memory shares = _getEffectiveMintSplits(collection, tokenId);
        if (shares.length == 0) revert NoShares();
        if (msg.value == 0) revert InvalidAmount();

        uint256 totalAmount = msg.value;

        // Send ETH directly to each recipient
        for (uint i = 0; i < shares.length; i++) {
            uint256 shareAmount = (totalAmount * shares[i].percentage) / 10000;
            if (shareAmount > 0) {
                (bool success, ) = payable(shares[i].account).call{
                    value: shareAmount
                }("");
                if (!success) revert TransferFailed();
            }
        }

        emit PaymentDistributed(collection, tokenId, totalAmount);
    }

    /**
     * @notice Distributes mint payment with direct transfers to recipients (ERC20)
     * @param collection The NFT collection address
     * @param tokenId The token ID being minted
     * @param token The ERC20 token address (USDC, DAI, etc.)
     * @param amount The amount of tokens to distribute
     */
    function distributeMintPaymentERC20(
        address collection,
        uint256 tokenId,
        address token,
        uint256 amount
    ) external nonReentrant {
        Share[] memory shares = _getEffectiveMintSplits(collection, tokenId);
        if (shares.length == 0) revert NoShares();
        if (token == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();

        IERC20 tokenContract = IERC20(token);

        // Transfer tokens from sender to this contract first
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        // Distribute tokens directly to each recipient
        for (uint i = 0; i < shares.length; i++) {
            uint256 shareAmount = (amount * shares[i].percentage) / 10000;
            if (shareAmount > 0) {
                tokenContract.safeTransfer(shares[i].account, shareAmount);
            }
        }

        emit ERC20PaymentDistributed(collection, tokenId, token, amount);
    }

    /**
     * @notice Distributes payment with cascade logic for remixes/playlists (ETH)
     * @param collection The NFT collection address
     * @param tokenId The token ID being sold
     */
    function distributeCascadePayment(
        address collection,
        uint256 tokenId
    ) external payable nonReentrant {
        if (msg.value == 0) revert InvalidAmount();

        uint256 totalAmount = msg.value;
        uint256 remainingAmount = totalAmount;

        // Handle cascade to original sources DIRECTLY
        address[] memory sources = inheritedFrom[tokenId];
        if (sources.length > 0) {
            uint96 cascadePercent = cascadePercentage[tokenId];
            if (cascadePercent > 0) {
                uint256 cascadeAmount = (totalAmount * cascadePercent) / 10000;
                uint256 perSource = cascadeAmount / sources.length;

                // Send ETH directly to each source
                for (uint i = 0; i < sources.length; i++) {
                    if (perSource > 0) {
                        (bool success, ) = payable(sources[i]).call{
                            value: perSource
                        }("");
                        if (!success) revert TransferFailed();
                    }
                }

                remainingAmount -= cascadeAmount;
            }
        }

        // Distribute remaining amount DIRECTLY according to splits
        Share[] memory shares = _getEffectiveMintSplits(collection, tokenId);
        if (shares.length > 0) {
            for (uint i = 0; i < shares.length; i++) {
                uint256 shareAmount = (remainingAmount * shares[i].percentage) /
                    10000;
                if (shareAmount > 0) {
                    (bool success, ) = payable(shares[i].account).call{
                        value: shareAmount
                    }("");
                    if (!success) revert TransferFailed();
                }
            }
        }

        emit PaymentDistributed(collection, tokenId, totalAmount);
    }

    /**
     * @notice Distributes payment with cascade logic for remixes/playlists (ERC20)
     * @param collection The NFT collection address
     * @param tokenId The token ID being sold
     * @param token The ERC20 token address
     * @param amount The amount of tokens to distribute
     */
    function distributeCascadePaymentERC20(
        address collection,
        uint256 tokenId,
        address token,
        uint256 amount
    ) external nonReentrant {
        if (token == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();

        IERC20 tokenContract = IERC20(token);

        // Transfer tokens from sender to this contract first
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        uint256 remainingAmount = amount;

        // Handle cascade to original sources DIRECTLY
        address[] memory sources = inheritedFrom[tokenId];
        if (sources.length > 0) {
            uint96 cascadePercent = cascadePercentage[tokenId];
            if (cascadePercent > 0) {
                uint256 cascadeAmount = (amount * cascadePercent) / 10000;
                uint256 perSource = cascadeAmount / sources.length;

                // Send tokens directly to each source
                for (uint i = 0; i < sources.length; i++) {
                    if (perSource > 0) {
                        tokenContract.safeTransfer(sources[i], perSource);
                    }
                }

                remainingAmount -= cascadeAmount;
            }
        }

        // Distribute remaining amount DIRECTLY according to splits
        Share[] memory shares = _getEffectiveMintSplits(collection, tokenId);
        if (shares.length > 0) {
            for (uint i = 0; i < shares.length; i++) {
                uint256 shareAmount = (remainingAmount * shares[i].percentage) /
                    10000;
                if (shareAmount > 0) {
                    tokenContract.safeTransfer(shares[i].account, shareAmount);
                }
            }
        }

        emit ERC20PaymentDistributed(collection, tokenId, token, amount);
    }

    /**
     * @notice Gets effective mint splits (token-specific or collection-wide)
     * @param collection The NFT collection address
     * @param tokenId The token ID
     * @return Array of effective mint splits
     */
    function _getEffectiveMintSplits(
        address collection,
        uint256 tokenId
    ) internal view returns (Share[] memory) {
        // Try token-specific splits first
        if (mintSplits[collection][tokenId].length > 0) {
            return mintSplits[collection][tokenId];
        }
        // Fall back to collection-wide splits
        return collectionMintSplits[collection];
    }

    /**
     * @notice Gets effective resale royalties (token-specific or collection-wide)
     * @param collection The NFT collection address
     * @param tokenId The token ID
     * @return Array of effective resale royalties
     */
    function _getEffectiveResaleRoyalties(
        address collection,
        uint256 tokenId
    ) internal view returns (Share[] memory) {
        // Try token-specific royalties first
        if (resaleRoyalties[collection][tokenId].length > 0) {
            return resaleRoyalties[collection][tokenId];
        }
        // Fall back to collection-wide royalties
        return collectionResaleRoyalties[collection];
    }

    /**
     * @notice Gets the resale royalty information for a token
     * @param collection The NFT collection address
     * @param tokenId The token ID
     * @return Array of royalty shares
     */
    function getResaleInfo(
        address collection,
        uint256 tokenId
    ) external view returns (Share[] memory) {
        return _getEffectiveResaleRoyalties(collection, tokenId);
    }

    /**
     * @notice Gets the inherited sources for a remix/playlist token
     * @param tokenId The token ID
     * @return Array of source addresses this token inherits from
     */
    function getInheritedSources(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return inheritedFrom[tokenId];
    }

    /**
     * @notice Gets the mint splits for a token (effective splits)
     * @param collection The NFT collection address
     * @param tokenId The token ID
     * @return Array of mint revenue shares
     */
    function getMintSplits(
        address collection,
        uint256 tokenId
    ) external view returns (Share[] memory) {
        return _getEffectiveMintSplits(collection, tokenId);
    }

    /**
     * @notice Gets collection-wide mint splits
     * @param collection The NFT collection address
     * @return Array of collection mint splits
     */
    function getCollectionMintSplits(
        address collection
    ) external view returns (Share[] memory) {
        return collectionMintSplits[collection];
    }

    /**
     * @notice Gets collection-wide resale royalties
     * @param collection The NFT collection address
     * @return Array of collection resale royalties
     */
    function getCollectionResaleRoyalties(
        address collection
    ) external view returns (Share[] memory) {
        return collectionResaleRoyalties[collection];
    }

    /**
     * @notice Gets cascade percentage for a remix/playlist token
     * @param tokenId The token ID
     * @return The cascade percentage
     */
    function getCascadePercentage(
        uint256 tokenId
    ) external view returns (uint96) {
        return cascadePercentage[tokenId];
    }
}
