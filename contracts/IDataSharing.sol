// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IDataSharing
/// @notice Interface for the DataSharing contract handling access requests and audit logging.
interface IDataSharing {
    
    /// @notice Structure representing a single access attempt (Audit Log)
    struct AuditLogEntry {
        uint256 logId;
        address owner;
        address requester;
        string dataType;
        uint256 timestamp;
        bool granted;
    }

    /// @notice Emitted when a data access attempt is made, regardless of outcome
    event AccessAttempt(
        uint256 indexed logId,
        address indexed owner,
        address indexed requester,
        string dataType,
        bool granted,
        uint256 timestamp
    );

    /// @notice Request access to a user's data
    /// @param owner The address of the data owner
    /// @param dataType The type of data being requested (e.g., "CREDIT_TIER")
    /// @return success True if access is granted, false otherwise
    function accessData(address owner, string calldata dataType) external returns (bool);

    /// @notice Retrieve a specific audit log entry
    /// @param logId The unique identifier of the log
    function getAuditLog(uint256 logId) external view returns (AuditLogEntry memory);
}