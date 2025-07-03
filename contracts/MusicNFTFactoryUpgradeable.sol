// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./MusicCollectionUpgradeable.sol";
import "./interfaces/IMusicNFTFactory.sol";

/**
 * @title MusicNFTFactoryUpgradeable
 * @dev Factory upgradeable para crear colecciones NFT musicales upgradeables
 */
contract MusicNFTFactoryUpgradeable is
    Initializable,
    IMusicNFTFactory,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // Template del contrato de implementación para las colecciones
    address public collectionImplementation;

    // Almacena todas las colecciones creadas
    address[] public collections;

    // Mapeo de artistas a sus colecciones
    mapping(address => address[]) public artistCollections;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _collectionImplementation) public initializer {
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        collectionImplementation = _collectionImplementation;
    }

    /**
     * @dev Función requerida por UUPS para autorizar upgrades
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /**
     * @dev Obtener versión del factory para tracking de upgrades
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /**
     * @dev Actualiza la implementación del contrato de colección (solo owner)
     */
    function updateCollectionImplementation(
        address _newImplementation
    ) external onlyOwner {
        require(
            _newImplementation != address(0),
            "Invalid implementation address"
        );
        collectionImplementation = _newImplementation;
        emit ImplementationUpdated(_newImplementation);
    }

    /**
     * @dev Crea una nueva colección ERC1155 upgradeable usando proxy
     */
    function createCollection(
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory collectionMetadata,
        uint256 mintStartDate,
        uint256 mintEndDate,
        address paymentToken,
        address royaltyReceiver,
        uint96 royaltyFee,
        address artist,
        address revenueShare
    ) external nonReentrant returns (address) {
        // Preparar los datos de inicialización
        bytes memory initData = abi.encodeWithSelector(
            MusicCollectionUpgradeable.initialize.selector,
            name,
            symbol,
            baseURI,
            collectionMetadata,
            mintStartDate,
            mintEndDate,
            paymentToken,
            royaltyReceiver,
            royaltyFee,
            artist,
            revenueShare
        );

        // Crear proxy y inicializar
        ERC1967Proxy proxy = new ERC1967Proxy(
            collectionImplementation,
            initData
        );
        address newCollection = address(proxy);

        // Almacenar la colección en los arrays
        collections.push(newCollection);
        artistCollections[artist].push(newCollection);

        emit CollectionCreated(artist, newCollection, name, symbol);

        return newCollection;
    }

    /**
     * @dev Devuelve el número total de colecciones creadas
     */
    function getCollectionsCount() external view returns (uint256) {
        return collections.length;
    }

    /**
     * @dev Devuelve el número de colecciones de un artista específico
     */
    function getArtistCollectionsCount(
        address artist
    ) external view returns (uint256) {
        return artistCollections[artist].length;
    }

    /**
     * @dev Devuelve todas las colecciones de un artista
     */
    function getArtistCollections(
        address artist
    ) external view returns (address[] memory) {
        return artistCollections[artist];
    }

    /**
     * @dev Evento para tracking de actualizaciones de implementación
     */
    event ImplementationUpdated(address indexed newImplementation);
}
