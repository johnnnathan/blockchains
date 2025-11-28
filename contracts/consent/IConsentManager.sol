// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IConsentManager
/// @notice Interface for managing consent agreements between users and requesters.
interface IConsentManager {

    /// @notice Structure representing a user's consent entry
    struct Consent {
        uint256 consentId;
        address owner;
        address requester;
        string[] allowedDataTypes;
        uint256 startTime;
        uint256 expiryTime;
        bool active;
    }

    /// @notice Emitted when new consent is created
    event ConsentCreated(
        uint256 indexed consentId,
        address indexed owner,
        address indexed requester
    );

    /// @notice Emitted when consent is revoked
    event ConsentRevoked(
        uint256 indexed consentId,
        address indexed owner
    );


    error NotConsentOwner();
    error InvalidDuration();
    error InvalidRequester();
    error AlreadyExpired();
    error ConsentNotActive();


    /// @notice Create a new consent entry
    function setConsent(
        address requester,
        string[] calldata allowedDataTypes,
        uint256 durationDays
    ) external;

    /// @notice Revoke existing consent entry
    function revokeConsent(uint256 consentId) external;

    /// @notice Validate permission for a specific data type
    function checkConsent(
        address owner,
        address requester,
        string calldata dataType
    ) external view returns (bool);

    /// @notice View single consent object
    function getConsent(uint256 consentId)
        external
        view
        returns (Consent memory);

    /// @notice Get all consents owned by a user
    function getUserConsents(address owner)
        external
        view
        returns (uint256[] memory);
}
