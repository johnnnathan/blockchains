
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./DataSharing.sol";
import "./ConsentManager.sol";
import "./IRewardToken.sol";
import "./Types.sol";
import "./DataTypes.sol";
import "./MockRewardToken.sol";



// Minimal interface implementation for testing
contract DataSharingTest is Test {
    ConsentManager consentManager;
    MockRewardToken rewardToken;
    DataSharing dataSharing;

    address owner = address(1);
    address requester = address(2);
    address otherUser = address(3);

    string[] allowedDataTypes;

    function setUp() public {
        rewardToken = new MockRewardToken();
        consentManager = new ConsentManager(address(rewardToken));
        dataSharing = new DataSharing(address(consentManager));

        // Prepare allowed data types
        allowedDataTypes.push("email");
        allowedDataTypes.push("phone");

        // Grant consent from owner to requester
        vm.prank(owner);
        consentManager.setConsent(requester, allowedDataTypes, 30);
    }

    function testAccessDataWithConsent() public {
        // requester accessing owner's data
        vm.prank(requester);
        uint256 gasBefore = gasleft();
        bool permitted = dataSharing.accessData(owner, "email");
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for accessData (permitted)", gasUsed);

        assertEq(permitted, true);

        // Verify audit log
        IDataSharing.AuditLogEntry memory log = dataSharing.getAuditLog(1);
        assertEq(log.owner, owner);
        assertEq(log.requester, requester);
        assertEq(keccak256(bytes(log.dataType)), keccak256(bytes("email")));
        assertEq(log.granted, true);
    }

    function testAccessDataWithoutConsent() public {
        // otherUser trying to access owner's data
        vm.prank(otherUser);
        uint256 gasBefore = gasleft();
        bool permitted = dataSharing.accessData(owner, "email");
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for accessData (denied)", gasUsed);

        assertEq(permitted, false);

        // Verify audit log
        IDataSharing.AuditLogEntry memory log = dataSharing.getAuditLog(2);
        assertEq(log.owner, owner);
        assertEq(log.requester, otherUser);
        assertEq(keccak256(bytes(log.dataType)), keccak256(bytes("email")));
        assertEq(log.granted, false);
    }

    function testAuditLogIncrement() public {
        vm.prank(requester);
        dataSharing.accessData(owner, "email");

        vm.prank(otherUser);
        dataSharing.accessData(owner, "phone");

        // Check log IDs
        IDataSharing.AuditLogEntry memory log1 = dataSharing.getAuditLog(1);
        IDataSharing.AuditLogEntry memory log2 = dataSharing.getAuditLog(2);

        assertEq(log1.logId, 1);
        assertEq(log2.logId, 2);
    }

    function testInvalidConstructorReverts() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        new DataSharing(address(0));
    }
}
