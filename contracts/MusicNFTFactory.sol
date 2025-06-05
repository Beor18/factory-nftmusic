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
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory collectionMetadata,
        uint256 mintStartDate,
        uint256 mintEndDate,
        uint256 price,
        address paymentToken,
        address royaltyReceiver,
        uint96 royaltyFee,
        address artist,
        address revenueShare
    ) external nonReentrant returns (address) {
        // Crear nueva colección
        MusicCollection newCollection = new MusicCollection(
            name,
            symbol,
            baseURI,
            collectionMetadata,
            mintStartDate,
            mintEndDate,
            price,
            paymentToken,
            royaltyReceiver,
            royaltyFee,
            artist,
            revenueShare
        );

        // Almacenar la colección en los arrays
        collections.push(newCollection);
        artistCollections[artist].push(newCollection);

        emit CollectionCreated(artist, address(newCollection), name, symbol);

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
