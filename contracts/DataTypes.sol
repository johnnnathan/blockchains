
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct AuditLogEntry {
    uint256 logId;
    address owner;
    address requester;
    string dataType;
    bool granted;
}
