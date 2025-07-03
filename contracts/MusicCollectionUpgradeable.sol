// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IMusicCollection.sol";
import "./interfaces/IRevenueShare.sol";

/**
 * @title MusicCollectionUpgradeable
 * @dev Versión upgradeable del contrato ERC1155 para colecciones NFT musicales
 */
contract MusicCollectionUpgradeable is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IMusicCollection
{
    using Strings for uint256;

    // Información básica de la colección
    string public name;
    string public symbol;
    string public baseURI;

    // Metadatos adicionales de la colección
    string public collectionMetadata;

    // Metadatos específicos por track/token
    mapping(uint256 => string) private _tokenURIs;

    // Configuración de ventas
    uint256 public mintStartDate;
    uint256 public mintEndDate;
    address public paymentToken; // Dirección del token ERC20 para pagos, address(0) para ETH nativo

    // Mapping de tokens ERC20 aceptados con sus precios respectivos
    mapping(address => uint256) public acceptedTokens; // address => price in tokens

    // Límites de mint
    mapping(uint256 => uint256) public maxSupply; // tokenId => max supply

    address public revenueShare;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _collectionMetadata,
        uint256 _mintStartDate,
        uint256 _mintEndDate,
        address _paymentToken,
        address _royaltyReceiver,
        uint96 _royaltyFee,
        address initialOwner,
        address _revenueShare
    ) public initializer {
        __ERC1155_init(_baseURI);
        __ERC1155Supply_init();
        __ERC2981_init();
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        collectionMetadata = _collectionMetadata;
        mintStartDate = _mintStartDate;
        mintEndDate = _mintEndDate;
        paymentToken = _paymentToken;
        revenueShare = _revenueShare;

        // Configurar royalties usando ERC2981
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFee);
    }

    /**
     * @dev Función requerida por UUPS para autorizar upgrades
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev Obtener versión del contrato para tracking de upgrades
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /**
     * @dev Configura el suministro máximo para un tokenId específico
     */
    function setMaxSupply(uint256 tokenId, uint256 supply) external onlyOwner {
        maxSupply[tokenId] = supply;
        emit MaxSupplyUpdated(tokenId, supply);
    }

    /**
     * @dev Añade un token ERC20 como método de pago aceptado
     */
    function addPaymentToken(
        address _token,
        uint256 _price
    ) external onlyOwner {
        acceptedTokens[_token] = _price;
        emit PaymentTokenAdded(_token, _price);
    }

    /**
     * @dev Actualiza las fechas de mint
     */
    function setMintDates(
        uint256 _startDate,
        uint256 _endDate
    ) external onlyOwner {
        if (_startDate >= _endDate) revert InvalidDates();
        mintStartDate = _startDate;
        mintEndDate = _endDate;
        emit MintDatesUpdated(_startDate, _endDate);
    }

    /**
     * @dev Actualiza información de royalties
     */
    function setRoyaltyInfo(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit RoyaltyInfoUpdated(receiver, feeNumerator);
    }

    /**
     * @dev Establece metadatos específicos para un token/track
     */
    function setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) external onlyOwner {
        _tokenURIs[tokenId] = _tokenURI;
        emit TokenURIUpdated(tokenId, _tokenURI);
    }

    /**
     * @dev Establece metadatos para la colección
     */
    function setCollectionMetadata(
        string memory _collectionMetadata
    ) external onlyOwner {
        collectionMetadata = _collectionMetadata;
        emit CollectionMetadataUpdated(_collectionMetadata);
    }

    /**
     * @dev Mint pagando con token ERC20
     */
    function mintWithERC20(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 pricePerToken,
        address paymentTokenAddress,
        string memory tokenMetadata
    ) external nonReentrant {
        if (block.timestamp < mintStartDate) revert MintNotStarted();
        if (block.timestamp > mintEndDate) revert MintEnded();
        if (
            maxSupply[tokenId] != 0 &&
            totalSupply(tokenId) + amount > maxSupply[tokenId]
        ) revert ExceedsMaxSupply();
        if (acceptedTokens[paymentTokenAddress] == 0) revert UnsupportedToken();

        uint256 totalCost = pricePerToken * amount;

        if (totalCost > 0) {
            if (revenueShare != address(0)) {
                // Transferir tokens del usuario al contrato RevenueShare y distribuir
                IERC20(paymentTokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    totalCost
                );

                // Aprobar al RevenueShare para que pueda distribuir
                IERC20(paymentTokenAddress).approve(revenueShare, totalCost);

                // Delegar completamente la transferencia y distribución al RevenueShare
                IRevenueShare(revenueShare).distributeMintPaymentERC20(
                    address(this),
                    tokenId,
                    paymentTokenAddress,
                    totalCost
                );
            } else {
                // Si no hay RevenueShare, transferir directamente al owner
                IERC20(paymentTokenAddress).transferFrom(
                    msg.sender,
                    owner(),
                    totalCost
                );
            }
        }

        // Si es la primera vez que se acuña este token, establecer sus metadatos
        if (totalSupply(tokenId) == 0 && bytes(tokenMetadata).length > 0) {
            _tokenURIs[tokenId] = tokenMetadata;
            emit TokenURIUpdated(tokenId, tokenMetadata);
        }

        // Mint los tokens NFT
        _mint(to, tokenId, amount, "");

        emit TokenMintedWithERC20(
            to,
            tokenId,
            amount,
            paymentTokenAddress,
            totalCost
        );
    }

    /**
     * @dev Mint con pago en ETH nativo
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 pricePerToken,
        string memory tokenMetadata
    ) external payable nonReentrant {
        if (block.timestamp < mintStartDate) revert MintNotStarted();
        if (block.timestamp > mintEndDate) revert MintEnded();
        if (
            maxSupply[tokenId] != 0 &&
            totalSupply(tokenId) + amount > maxSupply[tokenId]
        ) revert ExceedsMaxSupply();

        uint256 totalCost = pricePerToken * amount;
        if (totalCost > 0) {
            if (msg.value < totalCost) revert InsufficientPayment();

            if (revenueShare != address(0)) {
                // Distribuir pago a través del RevenueShare contract
                IRevenueShare(revenueShare).distributeMintPayment{
                    value: msg.value
                }(address(this), tokenId);
            } else {
                // Si no hay RevenueShare, enviar ETH directamente al owner
                (bool success, ) = payable(owner()).call{value: msg.value}("");
                require(success, "Transfer to owner failed");
            }
        }

        // Si es la primera vez que se acuña este token, establecer sus metadatos
        if (totalSupply(tokenId) == 0 && bytes(tokenMetadata).length > 0) {
            _tokenURIs[tokenId] = tokenMetadata;
            emit TokenURIUpdated(tokenId, tokenMetadata);
        }

        // Mint los tokens NFT
        _mint(to, tokenId, amount, "");

        emit TokenMintedWithETH(to, tokenId, amount, msg.value);
    }

    /**
     * @dev Mint gratuito (solo para el propietario)
     */
    function freeMint(
        address to,
        uint256 tokenId,
        uint256 amount,
        string memory tokenMetadata
    ) external onlyOwner {
        if (
            maxSupply[tokenId] != 0 &&
            totalSupply(tokenId) + amount > maxSupply[tokenId]
        ) revert ExceedsMaxSupply();

        // Si es la primera vez que se acuña este token, establecer sus metadatos
        if (totalSupply(tokenId) == 0 && bytes(tokenMetadata).length > 0) {
            _tokenURIs[tokenId] = tokenMetadata;
            emit TokenURIUpdated(tokenId, tokenMetadata);
        }

        // Mint los tokens NFT
        _mint(to, tokenId, amount, "");

        emit TokenMinted(to, tokenId, amount);
    }

    /**
     * @dev Devuelve el URI para un token específico
     */
    function uri(
        uint256 tokenId
    )
        public
        view
        override(ERC1155Upgradeable, IMusicCollection)
        returns (string memory)
    {
        string memory tokenURI = _tokenURIs[tokenId];

        // Si hay un URI específico para este token, devolverlo
        if (bytes(tokenURI).length > 0) {
            return tokenURI;
        }

        // De lo contrario, usar el enfoque tradicional baseURI + tokenId
        return string(abi.encodePacked(baseURI));
    }

    /**
     * @dev Actualiza el URI base para todos los tokens
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    /**
     * @dev Ver si el contrato soporta una interfaz específica
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Override requerido por Solidity
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._update(from, to, ids, values);
    }
}
