// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IDataSharing.sol";
import "./IConsentManager.sol";

/// @title DataSharing
/// @notice Enforces consent checks and logs all data access attempts.
contract DataSharing is IDataSharing {
    
    /// @notice Reference to the ConsentManager for permission validation
    IConsentManager public immutable consentManager;

    /// @notice Counter for generating unique log IDs
    uint256 private nextLogId;

    /// @notice Storage for audit logs: logId --> AuditLogEntry
    mapping(uint256 => AuditLogEntry) private auditLogs;

    error InvalidAddress();

    /// @param _consentManager Address of the deployed ConsentManager contract
    constructor(address _consentManager) {
        if (_consentManager == address(0)) revert InvalidAddress();
        consentManager = IConsentManager(_consentManager);
        nextLogId = 1;
    }

    /// @inheritdoc IDataSharing
    function accessData(address owner, string calldata dataType) external override returns (bool) {
        // 1. Check consent validty via ConsentManager. This validates if the consent exists, is active, hasn't expired, and includes the dataType
        bool isPermitted = consentManager.checkConsent(owner, msg.sender, dataType);

        // 2. Create Audit Log Entry
        uint256 logId = nextLogId++;
        AuditLogEntry memory entry = AuditLogEntry({
            logId: logId,
            owner: owner,
            requester: msg.sender,
            dataType: dataType,
            timestamp: block.timestamp,
            granted: isPermitted
        });

        // 3. Store the log permanently on-chain
        auditLogs[logId] = entry;

        // 4. Emit event for off-chain indexing
        emit AccessAttempt(
            logId, 
            owner, 
            msg.sender, 
            dataType, 
            isPermitted, 
            block.timestamp
        );

        return isPermitted;
    }

    /// @inheritdoc IDataSharing
    function getAuditLog(uint256 logId) external view override returns (AuditLogEntry memory) {
        return auditLogs[logId];
    }
}
