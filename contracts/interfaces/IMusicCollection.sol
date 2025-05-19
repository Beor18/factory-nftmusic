// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMusicCollection
 * @dev Interfaz para colecciones de música NFT
 */
interface IMusicCollection {
    /**
     * @dev Errores personalizados para manejo eficiente de errores
     */
    error MintNotStarted();
    error MintEnded();
    error ExceedsMaxSupply();
    error InvalidDates();
    error UnsupportedToken();
    error InsufficientPayment();
    error TransferFailed();

    /**
     * @dev Evento emitido cuando se mintea un token
     */
    event TokenMinted(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount
    );

    /**
     * @dev Evento emitido cuando se realiza un mint con pago en ETH
     */
    event TokenMintedWithETH(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 paymentAmount
    );

    /**
     * @dev Evento emitido cuando se realiza un mint con pago en ERC20
     */
    event TokenMintedWithERC20(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount,
        address indexed paymentToken,
        uint256 paymentAmount
    );

    /**
     * @dev Evento emitido cuando se añade un token de pago
     */
    event PaymentTokenAdded(address indexed token, uint256 price);

    /**
     * @dev Evento emitido cuando se actualiza la información de royalties
     */
    event RoyaltyInfoUpdated(address receiver, uint96 feeNumerator);

    /**
     * @dev Evento emitido cuando se actualizan las fechas de mint
     */
    event MintDatesUpdated(uint256 startDate, uint256 endDate);

    /**
     * @dev Evento emitido cuando se actualiza el suministro máximo
     */
    event MaxSupplyUpdated(uint256 indexed tokenId, uint256 maxSupply);

    /**
     * @dev Evento emitido cuando se actualiza el URI base
     */
    event BaseURIUpdated(string newBaseURI);

    /**
     * @dev Configura el suministro máximo para un tokenId específico
     */
    function setMaxSupply(uint256 tokenId, uint256 supply) external;

    /**
     * @dev Añade un token ERC20 como método de pago aceptado
     */
    function addPaymentToken(address _token, uint256 _price) external;

    /**
     * @dev Actualiza las fechas de mint
     */
    function setMintDates(uint256 _startDate, uint256 _endDate) external;

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
        address paymentTokenAddress
    ) external;

    /**
     * @dev Mint con pago en ETH nativo
     */
    function mint(address to, uint256 tokenId, uint256 amount) external payable;

    /**
     * @dev Mint gratuito (solo para el propietario)
     */
    function freeMint(address to, uint256 tokenId, uint256 amount) external;

    /**
     * @dev Devuelve el URI para un token específico
     */
    function uri(uint256 tokenId) external view returns (string memory);

    /**
     * @dev Actualiza el URI base para todos los tokens
     */
    function setBaseURI(string memory _newBaseURI) external;
}
