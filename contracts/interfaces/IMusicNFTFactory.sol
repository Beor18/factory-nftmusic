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
        address indexed collectionAddress,
        string name,
        string symbol
    );

    /**
     * @dev Crea una nueva colección ERC1155
     */
    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _mintStartDate,
        uint256 _mintEndDate,
        uint256 _price,
        address _paymentToken,
        address _royaltyReceiver,
        uint96 _royaltyFee
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
