// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./ConsentManager.sol";
import "./IRewardToken.sol";
import "./DataTypes.sol";
import "./MockRewardToken.sol";



contract ConsentManagerTest is Test {
    ConsentManager consentManager;
    MockRewardToken rewardToken;

    address owner = address(1);
    address requester = address(2);
    address otherUser = address(3);

    function setUp() public {
        rewardToken = new MockRewardToken();
        consentManager = new ConsentManager(address(rewardToken));
    }


    function testSetConsent() public {
        vm.prank(owner);

        string[] memory dataTypes = new string[](2);
        dataTypes[0] = "email";
        dataTypes[1] = "phone";

        uint256 gasBefore = gasleft();
        consentManager.setConsent(requester, dataTypes, 30);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for setConsent", gasUsed);

        uint256[] memory ids = consentManager.getUserConsents(owner);
        assertEq(ids.length, 1);

        ConsentManager.Consent memory c = consentManager.getConsent(ids[0]);
        assertEq(c.owner, owner);
        assertEq(c.requester, requester);
        assertEq(c.active, true);
        assertEq(keccak256(bytes(c.allowedDataTypes[0])), keccak256(bytes("email")));
        assertEq(keccak256(bytes(c.allowedDataTypes[1])), keccak256(bytes("phone")));
        assertEq(rewardToken.balanceOf(owner), 1 ether);
    }

    function testSetConsentInvalidRequester() public {
        vm.prank(owner);
        string[] memory dataTypes = new string[](1);

        vm.expectRevert(abi.encodeWithSignature("InvalidRequester()"));
        consentManager.setConsent(address(0), dataTypes, 10);
    }

    function testSetConsentInvalidDuration() public {
        vm.prank(owner);
        string[] memory dataTypes = new string[](1);
        dataTypes[0] = "email";

        vm.expectRevert(abi.encodeWithSignature("InvalidDuration()"));
        consentManager.setConsent(requester, dataTypes, 0);

        vm.expectRevert(abi.encodeWithSignature("InvalidDuration()"));
        consentManager.setConsent(requester, dataTypes, 100); // > 90 days
    }

    function testRevokeConsent() public {
        vm.prank(owner);
        string[] memory dataTypes = new string[](1);
        dataTypes[0] = "email";

        consentManager.setConsent(requester, dataTypes, 30);
        uint256 consentId = consentManager.getUserConsents(owner)[0];

        vm.prank(owner);
        uint256 gasBefore = gasleft();
        consentManager.revokeConsent(consentId);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for revokeConsent", gasUsed);

        ConsentManager.Consent memory c = consentManager.getConsent(consentId);
        assertEq(c.active, false);
    }

    function testRevokeConsentNotOwner() public {
        vm.prank(owner);
        string[] memory dataTypes = new string[](1);
        dataTypes[0] = "email";
        consentManager.setConsent(requester, dataTypes, 30);

        uint256 consentId = consentManager.getUserConsents(owner)[0];

        vm.prank(otherUser);
        vm.expectRevert(abi.encodeWithSignature("NotConsentOwner()"));
        consentManager.revokeConsent(consentId);
    }

    function testCheckConsent() public {
        vm.prank(owner);
        string[] memory dataTypes = new string[](2);
        dataTypes[0] = "email";
        dataTypes[1] = "phone";
        consentManager.setConsent(requester, dataTypes, 30);

        uint256 consentId = consentManager.getUserConsents(owner)[0];

        bool allowed = consentManager.checkConsent(owner, requester, "email");
        assertEq(allowed, true);

        allowed = consentManager.checkConsent(owner, requester, "address");
        assertEq(allowed, false);

        // Revoke and check
        vm.prank(owner);
        consentManager.revokeConsent(consentId);

        allowed = consentManager.checkConsent(owner, requester, "email");
        assertEq(allowed, false);
    }
}
