// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IRevenueShare {
    struct Share {
        address account;
        uint96 percentage; // base 10000 = 100%
    }

    function owner() external view returns (address);

    function name() external view returns (string memory);

    function description() external view returns (string memory);

    // Manager role functions
    function addManager(address manager) external;

    function removeManager(address manager) external;

    function isManager(address account) external view returns (bool);

    function setMintSplits(
        address collection,
        uint256 tokenId,
        Share[] memory shares
    ) external;

    function setResaleRoyalties(
        address collection,
        uint256 tokenId,
        Share[] memory shares
    ) external;

    function setInheritance(uint256 tokenId, address[] memory sources) external;

    function setCollectionMintSplits(
        address collection,
        Share[] memory shares
    ) external;

    function setCollectionResaleRoyalties(
        address collection,
        Share[] memory shares
    ) external;

    function setCascadePercentage(uint256 tokenId, uint96 percentage) external;

    function distributeMintPayment(
        address collection,
        uint256 tokenId
    ) external payable;

    function distributeMintPaymentERC20(
        address collection,
        uint256 tokenId,
        address token,
        uint256 amount
    ) external;

    function distributeCascadePayment(
        address collection,
        uint256 tokenId
    ) external payable;

    function distributeCascadePaymentERC20(
        address collection,
        uint256 tokenId,
        address token,
        uint256 amount
    ) external;

    function getResaleInfo(
        address collection,
        uint256 tokenId
    ) external view returns (Share[] memory);

    function getInheritedSources(
        uint256 tokenId
    ) external view returns (address[] memory);

    function getMintSplits(
        address collection,
        uint256 tokenId
    ) external view returns (Share[] memory);

    function getCollectionMintSplits(
        address collection
    ) external view returns (Share[] memory);

    function getCollectionResaleRoyalties(
        address collection
    ) external view returns (Share[] memory);

    function getCascadePercentage(
        uint256 tokenId
    ) external view returns (uint96);
}
