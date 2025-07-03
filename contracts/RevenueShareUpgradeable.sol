// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title RevenueShareUpgradeable
 * @notice Versión upgradeable que maneja distribución de ingresos para colecciones NFT con splits de pagos directos y royalties de reventa
 * @dev Implementa distribución de pagos directos con seguimiento de herencia para remixes/playlists
 * @dev Soporta tanto tokens nativos (ETH) como tokens ERC20 (USDC, DAI, etc.)
 * @dev Incluye sistema de roles de manager permitiendo que desarrolladores configuren splits mientras artistas mantienen ownership
 */
contract RevenueShareUpgradeable is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    /// @dev Role identifier for managers who can configure splits
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @dev Custom errors for gas efficiency
    error NotOwner();
    error NotAuthorized();
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

    address public owner;
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

    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyOwnerOrManager() {
        if (msg.sender != owner && !hasRole(MANAGER_ROLE, msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Inicializa el contrato RevenueShareUpgradeable
     * @param _owner Address que será propietario de este contrato de revenue share (artista)
     * @param _initialManager Address que recibirá el rol de manager inicialmente
     * @param _name Nombre del arreglo de revenue share
     * @param _description Descripción del arreglo de revenue share
     */
    function initialize(
        address _owner,
        address _initialManager,
        string memory _name,
        string memory _description
    ) public initializer {
        if (_owner == address(0)) revert InvalidAddress();
        if (bytes(_name).length == 0) revert EmptyName();

        __ReentrancyGuard_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        owner = _owner;
        name = _name;
        description = _description;

        // Configure roles: artist is admin, initial manager is _initialManager
        _grantRole(DEFAULT_ADMIN_ROLE, _owner); // Artist can manage roles
        _grantRole(MANAGER_ROLE, _initialManager); // Initial manager is manager initially
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
     * @notice Añade un nuevo manager (solo el owner puede hacer esto)
     * @param manager Address para otorgar rol de manager
     */
    function addManager(address manager) external onlyOwner {
        if (manager == address(0)) revert InvalidAddress();
        _grantRole(MANAGER_ROLE, manager);
        emit ManagerAdded(manager);
    }

    /**
     * @notice Remueve un manager (solo el owner puede hacer esto)
     * @param manager Address para revocar rol de manager
     */
    function removeManager(address manager) external onlyOwner {
        _revokeRole(MANAGER_ROLE, manager);
        emit ManagerRemoved(manager);
    }

    /**
     * @notice Verifica si una address tiene rol de manager
     * @param account Address a verificar
     * @return True si la address es un manager
     */
    function isManager(address account) external view returns (bool) {
        return hasRole(MANAGER_ROLE, account);
    }

    /**
     * @notice Establece los splits de ingresos por mint para un NFT específico
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token
     * @param shares Array de shares de ingresos que debe totalizar 10000 (100%)
     */
    function setMintSplits(
        address collection,
        uint256 tokenId,
        Share[] memory shares
    ) external onlyOwnerOrManager {
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
     * @notice Establece los splits de royalties de reventa para un NFT específico
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token
     * @param shares Array de shares de royalties que debe totalizar 10000 (100%)
     */
    function setResaleRoyalties(
        address collection,
        uint256 tokenId,
        Share[] memory shares
    ) external onlyOwnerOrManager {
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
     * @notice Establece las fuentes de herencia para tokens de remix/playlist
     * @param tokenId El ID del token remix/playlist
     * @param sources Array de direcciones de tokens fuente de los que este token hereda
     */
    function setInheritance(
        uint256 tokenId,
        address[] memory sources
    ) external onlyOwnerOrManager {
        inheritedFrom[tokenId] = sources;
        emit InheritanceSet(tokenId, sources);
    }

    /**
     * @notice Establece splits de mint para una colección completa (default para todos los tokens)
     * @param collection La dirección de la colección NFT
     * @param shares Array de shares de ingresos que debe totalizar 10000 (100%)
     */
    function setCollectionMintSplits(
        address collection,
        Share[] memory shares
    ) external onlyOwnerOrManager {
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
     * @notice Establece royalties de reventa para una colección completa (default para todos los tokens)
     * @param collection La dirección de la colección NFT
     * @param shares Array de shares de royalties que debe totalizar 10000 (100%)
     */
    function setCollectionResaleRoyalties(
        address collection,
        Share[] memory shares
    ) external onlyOwnerOrManager {
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
     * @notice Establece porcentaje de cascada para tokens de remix/playlist
     * @param tokenId El ID del token remix/playlist
     * @param percentage Porcentaje que va a las fuentes originales (base 10000)
     */
    function setCascadePercentage(
        uint256 tokenId,
        uint96 percentage
    ) external onlyOwnerOrManager {
        if (percentage > 10000) revert InvalidTotal(percentage);
        cascadePercentage[tokenId] = percentage;
    }

    /**
     * @notice Distribuye pago de mint con transferencias directas a destinatarios (ETH)
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token siendo minteado
     */
    function distributeMintPayment(
        address collection,
        uint256 tokenId
    ) external payable nonReentrant {
        Share[] memory shares = _getEffectiveMintSplits(collection, tokenId);
        if (shares.length == 0) revert NoShares();
        if (msg.value == 0) revert InvalidAmount();

        uint256 totalAmount = msg.value;

        // Envía ETH directamente a cada destinatario
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
     * @notice Distribuye pago de mint con transferencias directas a destinatarios (ERC20)
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token siendo minteado
     * @param token La dirección del token ERC20 (USDC, DAI, etc.)
     * @param amount La cantidad de tokens a distribuir
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

        // Transfiere tokens del sender a este contrato primero
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        // Distribuye tokens directamente a cada destinatario
        for (uint i = 0; i < shares.length; i++) {
            uint256 shareAmount = (amount * shares[i].percentage) / 10000;
            if (shareAmount > 0) {
                tokenContract.safeTransfer(shares[i].account, shareAmount);
            }
        }

        emit ERC20PaymentDistributed(collection, tokenId, token, amount);
    }

    /**
     * @notice Distribuye pago con lógica de cascada para remixes/playlists (ETH)
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token siendo vendido
     */
    function distributeCascadePayment(
        address collection,
        uint256 tokenId
    ) external payable nonReentrant {
        if (msg.value == 0) revert InvalidAmount();

        uint256 totalAmount = msg.value;
        uint256 remainingAmount = totalAmount;

        // Maneja cascada a fuentes originales DIRECTAMENTE
        address[] memory sources = inheritedFrom[tokenId];
        if (sources.length > 0) {
            uint96 cascadePercent = cascadePercentage[tokenId];
            if (cascadePercent > 0) {
                uint256 cascadeAmount = (totalAmount * cascadePercent) / 10000;
                uint256 perSource = cascadeAmount / sources.length;

                // Envía ETH directamente a cada fuente
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

        // Distribuye cantidad restante DIRECTAMENTE según splits
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
     * @notice Distribuye pago con lógica de cascada para remixes/playlists (ERC20)
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token siendo vendido
     * @param token La dirección del token ERC20
     * @param amount La cantidad de tokens a distribuir
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

        // Transfiere tokens del sender a este contrato primero
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);

        uint256 remainingAmount = amount;

        // Maneja cascada a fuentes originales DIRECTAMENTE
        address[] memory sources = inheritedFrom[tokenId];
        if (sources.length > 0) {
            uint96 cascadePercent = cascadePercentage[tokenId];
            if (cascadePercent > 0) {
                uint256 cascadeAmount = (amount * cascadePercent) / 10000;
                uint256 perSource = cascadeAmount / sources.length;

                // Envía tokens directamente a cada fuente
                for (uint i = 0; i < sources.length; i++) {
                    if (perSource > 0) {
                        tokenContract.safeTransfer(sources[i], perSource);
                    }
                }

                remainingAmount -= cascadeAmount;
            }
        }

        // Distribuye cantidad restante DIRECTAMENTE según splits
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
     * @notice Obtiene splits de mint efectivos (específicos de token o de toda la colección)
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token
     * @return Array de splits de mint efectivos
     */
    function _getEffectiveMintSplits(
        address collection,
        uint256 tokenId
    ) internal view returns (Share[] memory) {
        // Intenta splits específicos de token primero
        if (mintSplits[collection][tokenId].length > 0) {
            return mintSplits[collection][tokenId];
        }
        // Se devuelve a splits de toda la colección
        return collectionMintSplits[collection];
    }

    /**
     * @notice Obtiene royalties de reventa efectivos (específicos de token o de toda la colección)
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token
     * @return Array de royalties de reventa efectivos
     */
    function _getEffectiveResaleRoyalties(
        address collection,
        uint256 tokenId
    ) internal view returns (Share[] memory) {
        // Intenta royalties específicos de token primero
        if (resaleRoyalties[collection][tokenId].length > 0) {
            return resaleRoyalties[collection][tokenId];
        }
        // Se devuelve a royalties de toda la colección
        return collectionResaleRoyalties[collection];
    }

    /**
     * @notice Obtiene la información de royalties de reventa para un token
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token
     * @return Array de shares de royalties
     */
    function getResaleInfo(
        address collection,
        uint256 tokenId
    ) external view returns (Share[] memory) {
        return _getEffectiveResaleRoyalties(collection, tokenId);
    }

    /**
     * @notice Obtiene las fuentes heredadas para un token de remix/playlist
     * @param tokenId El ID del token
     * @return Array de direcciones de fuentes de las que este token hereda
     */
    function getInheritedSources(
        uint256 tokenId
    ) external view returns (address[] memory) {
        return inheritedFrom[tokenId];
    }

    /**
     * @notice Obtiene los splits de mint para un token (splits efectivos)
     * @param collection La dirección de la colección NFT
     * @param tokenId El ID del token
     * @return Array de shares de ingresos de mint
     */
    function getMintSplits(
        address collection,
        uint256 tokenId
    ) external view returns (Share[] memory) {
        return _getEffectiveMintSplits(collection, tokenId);
    }

    /**
     * @notice Obtiene splits de mint de toda la colección
     * @param collection La dirección de la colección NFT
     * @return Array de splits de mint de la colección
     */
    function getCollectionMintSplits(
        address collection
    ) external view returns (Share[] memory) {
        return collectionMintSplits[collection];
    }

    /**
     * @notice Obtiene royalties de reventa de toda la colección
     * @param collection La dirección de la colección NFT
     * @return Array de royalties de reventa de la colección
     */
    function getCollectionResaleRoyalties(
        address collection
    ) external view returns (Share[] memory) {
        return collectionResaleRoyalties[collection];
    }

    /**
     * @notice Obtiene porcentaje de cascada para un token de remix/playlist
     * @param tokenId El ID del token
     * @return El porcentaje de cascada
     */
    function getCascadePercentage(
        uint256 tokenId
    ) external view returns (uint96) {
        return cascadePercentage[tokenId];
    }
}
