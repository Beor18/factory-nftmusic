// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./RevenueShare.sol";

/**
 * @title RevenueShareFactory
 * @notice Factory contract for creating RevenueShare contracts for artists
 * @dev Manages the creation and tracking of RevenueShare contracts per artist
 */
contract RevenueShareFactory {
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

    /**
     * @notice Creates a new RevenueShare contract for an artist
     * @param artist The artist address who will own the RevenueShare contract
     * @param name Name of the revenue share arrangement
     * @param description Description of the revenue share arrangement
     * @return managerAddress The address of the newly created RevenueShare contract
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

        // Create new RevenueShare contract
        // Create new RevenueShare contract
        RevenueShare manager = new RevenueShare(
            artist,
            msg.sender,
            name,
            description
        );
        managerAddress = address(manager);

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
     * @notice Gets all revenue share managers for a specific artist
     * @param artist The artist address
     * @return Array of ManagerInfo structs for the artist
     */
    function getArtistManagers(
        address artist
    ) external view returns (ManagerInfo[] memory) {
        return artistManagers[artist];
    }

    /**
     * @notice Gets a specific manager info for an artist by index
     * @param artist The artist address
     * @param index The index of the manager
     * @return ManagerInfo struct for the specified manager
     */
    function getManagerByIndex(
        address artist,
        uint256 index
    ) external view returns (ManagerInfo memory) {
        require(index < artistManagers[artist].length, "Index out of bounds");
        return artistManagers[artist][index];
    }

    /**
     * @notice Gets the total number of managers created for an artist
     * @param artist The artist address
     * @return The total number of managers for the artist
     */
    function getArtistManagerCount(
        address artist
    ) external view returns (uint256) {
        return artistManagerCount[artist];
    }

    /**
     * @notice Gets the total number of managers created by this factory
     * @return The total number of managers created
     */
    function getTotalManagersCreated() external view returns (uint256) {
        return allManagers.length;
    }

    /**
     * @notice Gets a manager address by its global index
     * @param index The global index
     * @return The manager address at the specified index
     */
    function getManagerByGlobalIndex(
        uint256 index
    ) external view returns (address) {
        require(index < allManagers.length, "Index out of bounds");
        return allManagers[index];
    }

    /**
     * @notice Checks if an address is a manager created by this factory
     * @param managerAddress The address to check
     * @return True if the address is a manager created by this factory
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
