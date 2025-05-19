// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IMusicCollection.sol";

/**
 * @title MusicCollection
 * @dev Contrato ERC1155 para que artistas musicales creen colecciones NFT
 */
contract MusicCollection is
    ERC1155,
    ERC1155Supply,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    IMusicCollection
{
    using Strings for uint256;

    // Información básica de la colección
    string public name;
    string public symbol;
    string public baseURI;

    // Configuración de ventas
    uint256 public mintStartDate;
    uint256 public mintEndDate;
    uint256 public price;
    address public paymentToken; // Dirección del token ERC20 para pagos, address(0) para ETH nativo

    // Mapping de tokens ERC20 aceptados con sus precios respectivos
    mapping(address => uint256) public acceptedTokens; // address => price in tokens

    // Límites de mint
    mapping(uint256 => uint256) public maxSupply; // tokenId => max supply

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _mintStartDate,
        uint256 _mintEndDate,
        uint256 _price,
        address _paymentToken,
        address _royaltyReceiver,
        uint96 _royaltyFee,
        address initialOwner
    ) ERC1155(_baseURI) Ownable(initialOwner) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        mintStartDate = _mintStartDate;
        mintEndDate = _mintEndDate;
        price = _price;
        paymentToken = _paymentToken;

        // Configurar royalties usando ERC2981
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFee);
    }

    /**
     * @dev Configura el suministro máximo para un tokenId específico
     */
    function setMaxSupply(
        uint256 tokenId,
        uint256 supply
    ) external override onlyOwner {
        maxSupply[tokenId] = supply;
        emit MaxSupplyUpdated(tokenId, supply);
    }

    /**
     * @dev Añade un token ERC20 como método de pago aceptado
     */
    function addPaymentToken(
        address _token,
        uint256 _price
    ) external override onlyOwner {
        acceptedTokens[_token] = _price;
        emit PaymentTokenAdded(_token, _price);
    }

    /**
     * @dev Actualiza las fechas de mint
     */
    function setMintDates(
        uint256 _startDate,
        uint256 _endDate
    ) external override onlyOwner {
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
    ) external override onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit RoyaltyInfoUpdated(receiver, feeNumerator);
    }

    /**
     * @dev Mint pagando con token ERC20
     */
    function mintWithERC20(
        address to,
        uint256 tokenId,
        uint256 amount,
        address paymentTokenAddress
    ) external override nonReentrant {
        if (block.timestamp < mintStartDate) revert MintNotStarted();
        if (block.timestamp > mintEndDate) revert MintEnded();
        if (
            maxSupply[tokenId] != 0 &&
            totalSupply(tokenId) + amount > maxSupply[tokenId]
        ) revert ExceedsMaxSupply();
        if (acceptedTokens[paymentTokenAddress] == 0) revert UnsupportedToken();

        uint256 tokenPrice = acceptedTokens[paymentTokenAddress];
        uint256 totalCost = tokenPrice * amount;

        // Transferir tokens ERC20 directamente al propietario/artista
        IERC20(paymentTokenAddress).transferFrom(
            msg.sender,
            owner(),
            totalCost
        );

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
        uint256 amount
    ) external payable override nonReentrant {
        if (block.timestamp < mintStartDate) revert MintNotStarted();
        if (block.timestamp > mintEndDate) revert MintEnded();
        if (
            maxSupply[tokenId] != 0 &&
            totalSupply(tokenId) + amount > maxSupply[tokenId]
        ) revert ExceedsMaxSupply();

        uint256 totalCost = 0;
        if (price > 0) {
            totalCost = price * amount;
            if (msg.value < totalCost) revert InsufficientPayment();

            // Enviar el pago directamente al propietario
            (bool success, ) = payable(owner()).call{value: msg.value}("");
            if (!success) revert TransferFailed();
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
        uint256 amount
    ) external override onlyOwner {
        if (
            maxSupply[tokenId] != 0 &&
            totalSupply(tokenId) + amount > maxSupply[tokenId]
        ) revert ExceedsMaxSupply();

        // Mint los tokens NFT
        _mint(to, tokenId, amount, "");

        emit TokenMinted(to, tokenId, amount);
    }

    /**
     * @dev Devuelve el URI para un token específico
     */
    function uri(
        uint256 tokenId
    ) public view override(ERC1155, IMusicCollection) returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @dev Actualiza el URI base para todos los tokens
     */
    function setBaseURI(string memory _newBaseURI) external override onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    // Sobrescribir funciones requeridas
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }

    /**
     * @dev Implementación del soporte para interfaz (ERC2981 royalties)
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, ERC2981) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
