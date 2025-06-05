// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMusicNFTFactory
 * @dev Interfaz para el factory de colecciones de música NFT
 */
interface IMusicNFTFactory {
    /**
     * @dev Evento emitido cuando se crea una nueva colección
     */
    event CollectionCreated(
        address indexed artist,
        address indexed collection,
        string name,
        string symbol
    );

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
    ) external returns (address);

    /**
     * @dev Devuelve el número total de colecciones creadas
     */
    function getCollectionsCount() external view returns (uint256);

    /**
     * @dev Devuelve el número de colecciones de un artista específico
     */
    function getArtistCollectionsCount(
        address artist
    ) external view returns (uint256);
}
