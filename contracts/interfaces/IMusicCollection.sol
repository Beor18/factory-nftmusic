// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMusicCollection
 * @dev Interfaz para colecciones de música NFT
 */
interface IMusicCollection {
    /**
     * @dev Errores del contrato
     */
    error InvalidDates();
    error MintNotStarted();
    error MintEnded();
    error ExceedsMaxSupply();
    error UnsupportedToken();
    error InsufficientPayment();
    error TransferFailed();

    /**
     * @dev Eventos del contrato
     */
    event MaxSupplyUpdated(uint256 indexed tokenId, uint256 maxSupply);
    event PaymentTokenAdded(address indexed token, uint256 price);
    event MintDatesUpdated(uint256 startDate, uint256 endDate);
    event RoyaltyInfoUpdated(address receiver, uint96 feeNumerator);
    event BaseURIUpdated(string uri);
    event TokenMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount
    );
    event TokenMintedWithETH(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 cost
    );
    event TokenMintedWithERC20(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount,
        address token,
        uint256 cost
    );
    event TokenURIUpdated(uint256 indexed tokenId, string uri);
    event CollectionMetadataUpdated(string metadata);

    /**
     * @dev Establece el suministro máximo para un tokenId específico
     */
    function setMaxSupply(uint256 tokenId, uint256 supply) external;

    /**
     * @dev Añade un token ERC20 como método de pago aceptado
     */
    function addPaymentToken(address token, uint256 price) external;

    /**
     * @dev Actualiza las fechas de mint
     */
    function setMintDates(uint256 startDate, uint256 endDate) external;

    /**
     * @dev Actualiza información de royalties
     */
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external;

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
    ) external;

    /**
     * @dev Mint con pago en ETH nativo
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 pricePerToken,
        string memory tokenMetadata
    ) external payable;

    /**
     * @dev Mint gratuito (solo para el propietario)
     */
    function freeMint(
        address to,
        uint256 tokenId,
        uint256 amount,
        string memory tokenMetadata
    ) external;

    /**
     * @dev Actualiza el URI base para todos los tokens
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @dev Devuelve el URI para un token específico
     */
    function uri(uint256 tokenId) external view returns (string memory);
}
