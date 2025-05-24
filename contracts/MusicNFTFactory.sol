// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MusicCollection.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IMusicNFTFactory.sol";

/**
 * @title MusicNFTFactory
 * @dev Factory para que artistas musicales creen sus propias colecciones NFT
 */
contract MusicNFTFactory is IMusicNFTFactory, Ownable, ReentrancyGuard {
    // Almacena todas las colecciones creadas
    MusicCollection[] public collections;

    // Mapeo de artistas a sus colecciones
    mapping(address => MusicCollection[]) public artistCollections;

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Crea una nueva colección ERC1155
     */
    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _collectionMetadata,
        uint256 _mintStartDate,
        uint256 _mintEndDate,
        uint256 _price,
        address _paymentToken,
        address _royaltyReceiver,
        uint96 _royaltyFee
    ) external nonReentrant returns (address) {
        // Crear nueva colección
        MusicCollection newCollection = new MusicCollection(
            _name,
            _symbol,
            _baseURI,
            _collectionMetadata,
            _mintStartDate,
            _mintEndDate,
            _price,
            _paymentToken,
            _royaltyReceiver,
            _royaltyFee,
            msg.sender // El artista es el propietario de la colección
        );

        // Almacenar la colección en los arrays
        collections.push(newCollection);
        artistCollections[msg.sender].push(newCollection);

        emit CollectionCreated(
            msg.sender,
            address(newCollection),
            _name,
            _symbol
        );

        return address(newCollection);
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
}
