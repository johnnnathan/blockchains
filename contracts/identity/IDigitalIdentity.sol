// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../utils/Types.sol";

/// @title IDigitalIdentity
interface IDigitalIdentity {
    /// @notice Emitted when a new user registers
    event UserRegistered(
        address indexed userAddress,
        bytes32 indexed hashedIdentity,
        uint256 timestamp
    );

    /// @notice Emitted when a user updates their credit profile
    event CreditProfileUpdated(
        address indexed userAddress,
        uint256 timestamp
    );

    /// @notice Emitted when an off-chain reference is added
    event OffChainRefAdded(
        address indexed userAddress,
        string ref
    );

    // Errors
    /// @notice User is already registered
    error AlreadyRegistered();

    /// @notice User is not registered
    error NotRegistered();

    /// @notice Invalid input parameter
    error InvalidInput();

    /// @notice Unauthorized access attempt
    error Unauthorized();

    // Functions

    /// @notice Register a new user with hashed identity attributes
    function registerUser(
        bytes32 hashedIdentity,
        bytes32 hashedCreditTier,
        bytes32 hashedIncomeTier,
        bytes32 hashedDebtRatio
    ) external;

    /// @notice Update user's credit profile
    function updateCreditProfile(
        bytes32 hashedCreditTier,
        bytes32 hashedIncomeTier,
        bytes32 hashedDebtRatio
    ) external;

    /// @notice Add a reference to off-chain data storage
    /// @param ref Off-chain storage reference
    function addOffChainRef(string calldata ref) external;

    /// @notice Get user information
    function getUser(address userAddress)
        external
        view
        returns (Types.User memory user);

    /// @notice Get user's credit profile
    function getCreditProfile(address userAddress)
        external
        view
        returns (Types.CreditProfile memory creditProfile);

    /// @notice Check if a user is registered
    function isUserRegistered(address userAddress)
        external
        view
        returns (bool);

    /// @notice Get all off-chain references for a user
    /// @return references Array of off-chain storage references
    function getOffChainRefs(address userAddress)
        external
        view
        returns (string[] memory);
}
