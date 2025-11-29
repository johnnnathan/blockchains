// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDigitalIdentity.sol";
import "./Types.sol";

/// @title DigitalIdentity
/// @dev Stores hashed identity attributes on-chain for privacy
contract DigitalIdentity is IDigitalIdentity {
    /// @notice Mapping from user address to User struct
    mapping(address => Types.User) private users;

    /// @notice Ensures the caller is registered
    modifier onlyRegistered() {
        if (!users[msg.sender].isRegistered) {
            revert NotRegistered();
        }
        _;
    }

    /// @notice Ensures the caller is not already registered
    modifier notRegistered() {
        if (users[msg.sender].isRegistered) {
            revert AlreadyRegistered();
        }
        _;
    }

    /// @inheritdoc IDigitalIdentity
    function registerUser(
        bytes32 hashedIdentity,
        bytes32 hashedCreditTier,
        bytes32 hashedIncomeTier,
        bytes32 hashedDebtRatio
    ) external override notRegistered {
        if (hashedIdentity == bytes32(0)) {
            revert InvalidInput();
        }
        if (
            hashedCreditTier == bytes32(0) ||
            hashedIncomeTier == bytes32(0) ||
            hashedDebtRatio == bytes32(0)
        ) {
            revert InvalidInput();
        }

        // Create credit profile
        Types.CreditProfile memory creditProfile = Types.CreditProfile({
            hashedCreditTier: hashedCreditTier,
            hashedIncomeTier: hashedIncomeTier,
            hashedDebtRatio: hashedDebtRatio,
            lastUpdated: block.timestamp,
            isActive: true
        });

        // Create user
        Types.User storage user = users[msg.sender];
        user.userAddress = msg.sender;
        user.hashedIdentity = hashedIdentity;
        user.creditProfile = creditProfile;
        user.registrationTime = block.timestamp;
        user.isRegistered = true;

        emit UserRegistered(msg.sender, hashedIdentity, block.timestamp);
    }

    /// @inheritdoc IDigitalIdentity
    function updateCreditProfile(
        bytes32 hashedCreditTier,
        bytes32 hashedIncomeTier,
        bytes32 hashedDebtRatio
    ) external override onlyRegistered {
        if (
            hashedCreditTier == bytes32(0) ||
            hashedIncomeTier == bytes32(0) ||
            hashedDebtRatio == bytes32(0)
        ) {
            revert InvalidInput();
        }

        Types.User storage user = users[msg.sender];
        user.creditProfile.hashedCreditTier = hashedCreditTier;
        user.creditProfile.hashedIncomeTier = hashedIncomeTier;
        user.creditProfile.hashedDebtRatio = hashedDebtRatio;
        user.creditProfile.lastUpdated = block.timestamp;

        emit CreditProfileUpdated(msg.sender, block.timestamp);
    }

    /// @inheritdoc IDigitalIdentity
    function addOffChainRef(string calldata ref)
        external
        override
        onlyRegistered
    {
        if (bytes(ref).length == 0) {
            revert InvalidInput();
        }

        users[msg.sender].offChainRefs.push(ref);

        emit OffChainRefAdded(msg.sender, ref);
    }

    /// @inheritdoc IDigitalIdentity
    function getUser(address userAddress)
        external
        view
        override
        returns (Types.User memory)
    {
        if (!users[userAddress].isRegistered) {
            revert NotRegistered();
        }
        return users[userAddress];
    }

    /// @inheritdoc IDigitalIdentity
    function getCreditProfile(address userAddress)
        external
        view
        override
        returns (Types.CreditProfile memory)
    {
        if (!users[userAddress].isRegistered) {
            revert NotRegistered();
        }
        return users[userAddress].creditProfile;
    }

    /// @inheritdoc IDigitalIdentity
    function isUserRegistered(address userAddress)
        external
        view
        override
        returns (bool)
    {
        return users[userAddress].isRegistered;
    }

    /// @inheritdoc IDigitalIdentity
    function getOffChainRefs(address userAddress)
        external
        view
        override
        returns (string[] memory)
    {
        if (!users[userAddress].isRegistered) {
            revert NotRegistered();
        }
        return users[userAddress].offChainRefs;
    }
}
