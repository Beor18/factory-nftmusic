// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./RevenueShareUpgradeable.sol";

/**
 * @title RevenueShareFactoryUpgradeable
 * @notice Versión upgradeable del factory para crear contratos RevenueShare para artistas
 * @dev Maneja la creación y seguimiento de contratos RevenueShare por artista usando proxies upgradeables
 */
contract RevenueShareFactoryUpgradeable is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @dev Custom errors for gas efficiency
    error InvalidArtist();
    error EmptyName();
    error EmptyDescription();
    error ManagerCreationFailed();

    struct ManagerInfo {
        address managerAddress;
        string name;
        string description;
        uint256 createdAt;
    }

    /// @dev Implementation address for RevenueShareUpgradeable
    address public revenueShareImplementation;

    /// @dev Mapping from artist address to their revenue share managers
    mapping(address => ManagerInfo[]) public artistManagers;

    /// @dev Mapping to track total managers created per artist
    mapping(address => uint256) public artistManagerCount;

    /// @dev Array of all created managers for enumeration
    address[] public allManagers;

    /// @dev Events for comprehensive tracking
    event RevenueShareCreated(
        address indexed artist,
        address indexed manager,
        string name,
        uint256 indexed managerId
    );

    event ManagerInfoUpdated(
        address indexed artist,
        address indexed manager,
        string name,
        string description
    );

    event ImplementationUpdated(address indexed newImplementation);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Inicializa el contrato RevenueShareFactoryUpgradeable
     * @param _revenueShareImplementation Dirección de la implementación de RevenueShareUpgradeable
     * @param initialOwner Propietario inicial del factory
     */
    function initialize(
        address _revenueShareImplementation,
        address initialOwner
    ) public initializer {
        if (_revenueShareImplementation == address(0)) revert InvalidArtist();
        if (initialOwner == address(0)) revert InvalidArtist();

        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        revenueShareImplementation = _revenueShareImplementation;
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
     * @notice Actualiza la implementación de RevenueShare
     * @param newImplementation Nueva dirección de implementación
     */
    function updateRevenueShareImplementation(
        address newImplementation
    ) external onlyOwner {
        if (newImplementation == address(0)) revert InvalidArtist();
        revenueShareImplementation = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }

    /**
     * @notice Crea un nuevo contrato RevenueShare para un artista usando proxy upgradeable
     * @param artist La dirección del artista que será propietario del contrato RevenueShare
     * @param name Nombre del arreglo de revenue share
     * @param description Descripción del arreglo de revenue share
     * @return managerAddress La dirección del contrato RevenueShare recién creado
     */
    function createRevenueShare(
        address artist,
        string memory name,
        string memory description
    ) external returns (address managerAddress) {
        // Input validation
        if (artist == address(0)) revert InvalidArtist();
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(description).length == 0) revert EmptyDescription();

        // Encode initialize call data
        bytes memory initData = abi.encodeWithSelector(
            RevenueShareUpgradeable.initialize.selector,
            artist,
            msg.sender,
            name,
            description
        );

        // Create new proxy pointing to RevenueShareUpgradeable implementation
        ERC1967Proxy proxy = new ERC1967Proxy(
            revenueShareImplementation,
            initData
        );

        managerAddress = address(proxy);

        // Verify contract creation
        if (managerAddress == address(0)) revert ManagerCreationFailed();

        // Store manager info
        uint256 managerId = artistManagerCount[artist];
        artistManagers[artist].push(
            ManagerInfo({
                managerAddress: managerAddress,
                name: name,
                description: description,
                createdAt: block.timestamp
            })
        );

        // Update counters
        artistManagerCount[artist]++;
        allManagers.push(managerAddress);

        emit RevenueShareCreated(artist, managerAddress, name, managerId);
    }

    /**
     * @notice Obtiene todos los managers de revenue share para un artista específico
     * @param artist La dirección del artista
     * @return Array de structs ManagerInfo para el artista
     */
    function getArtistManagers(
        address artist
    ) external view returns (ManagerInfo[] memory) {
        return artistManagers[artist];
    }

    /**
     * @notice Obtiene información específica de un manager para un artista por índice
     * @param artist La dirección del artista
     * @param index El índice del manager
     * @return Struct ManagerInfo para el manager especificado
     */
    function getManagerByIndex(
        address artist,
        uint256 index
    ) external view returns (ManagerInfo memory) {
        require(index < artistManagers[artist].length, "Index out of bounds");
        return artistManagers[artist][index];
    }

    /**
     * @notice Obtiene el número total de managers creados para un artista
     * @param artist La dirección del artista
     * @return El número total de managers para el artista
     */
    function getArtistManagerCount(
        address artist
    ) external view returns (uint256) {
        return artistManagerCount[artist];
    }

    /**
     * @notice Obtiene el número total de managers creados por este factory
     * @return El número total de managers creados
     */
    function getTotalManagersCreated() external view returns (uint256) {
        return allManagers.length;
    }

    /**
     * @notice Obtiene una dirección de manager por su índice global
     * @param index El índice global
     * @return La dirección del manager en el índice especificado
     */
    function getManagerByGlobalIndex(
        uint256 index
    ) external view returns (address) {
        require(index < allManagers.length, "Index out of bounds");
        return allManagers[index];
    }

    /**
     * @notice Verifica si una dirección es un manager creado por este factory
     * @param managerAddress La dirección a verificar
     * @return True si la dirección es un manager creado por este factory
     */
    function isManagerCreatedByFactory(
        address managerAddress
    ) external view returns (bool) {
        for (uint256 i = 0; i < allManagers.length; i++) {
            if (allManagers[i] == managerAddress) {
                return true;
            }
        }
        return false;
    }
}
