
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./DigitalIdentity.sol";
import "./Types.sol";
import "./DataTypes.sol";

contract DigitalIdentityTest is Test {
    DigitalIdentity digitalIdentity;

    address user = address(1);
    address otherUser = address(2);

    bytes32 hashedIdentity = keccak256(abi.encodePacked("user-identity"));
    bytes32 credit = keccak256(abi.encodePacked("A"));
    bytes32 income = keccak256(abi.encodePacked("HIGH"));
    bytes32 debt = keccak256(abi.encodePacked("LOW"));

    function setUp() public {
        digitalIdentity = new DigitalIdentity();
    }

    function testRegisterUser() public {
        vm.prank(user);
        uint256 gasBefore = gasleft();
        digitalIdentity.registerUser(hashedIdentity, credit, income, debt);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for registerUser", gasUsed);

        Types.User memory u = digitalIdentity.getUser(user);
        assertEq(u.isRegistered, true);
        assertEq(u.hashedIdentity, hashedIdentity);
        assertEq(u.creditProfile.hashedCreditTier, credit);
    }

    function testDoubleRegistrationReverts() public {
        vm.prank(user);
        digitalIdentity.registerUser(hashedIdentity, credit, income, debt);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("AlreadyRegistered()"));
        digitalIdentity.registerUser(hashedIdentity, credit, income, debt);
    }

    function testUpdateCreditProfile() public {
        vm.prank(user);
        digitalIdentity.registerUser(hashedIdentity, credit, income, debt);

        bytes32 newCredit = keccak256(abi.encodePacked("B"));
        vm.prank(user);
        uint256 gasBefore = gasleft();
        digitalIdentity.updateCreditProfile(newCredit, income, debt);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for updateCreditProfile", gasUsed);

        Types.CreditProfile memory cp = digitalIdentity.getCreditProfile(user);
        assertEq(cp.hashedCreditTier, newCredit);
    }

    function testUpdateCreditProfileNotRegistered() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("NotRegistered()"));
        digitalIdentity.updateCreditProfile(credit, income, debt);
    }

    function testAddOffChainRef() public {
        vm.prank(user);
        digitalIdentity.registerUser(hashedIdentity, credit, income, debt);

        vm.prank(user);
        uint256 gasBefore = gasleft();
        digitalIdentity.addOffChainRef("ipfs://abc");
        digitalIdentity.addOffChainRef("ipfs://def");
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for addOffChainRef (2 refs)", gasUsed);

        string[] memory refs = digitalIdentity.getOffChainRefs(user);
        assertEq(refs.length, 2);
        assertEq(refs[0], "ipfs://abc");
        assertEq(refs[1], "ipfs://def");
    }

    function testAddOffChainRefNotRegistered() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("NotRegistered()"));
        digitalIdentity.addOffChainRef("ipfs://abc");
    }

    function testGetUserNotRegisteredReverts() public {
        vm.expectRevert(abi.encodeWithSignature("NotRegistered()"));
        digitalIdentity.getUser(otherUser);
    }

    function testGetCreditProfileNotRegisteredReverts() public {
        vm.expectRevert(abi.encodeWithSignature("NotRegistered()"));
        digitalIdentity.getCreditProfile(otherUser);
    }

    function testGetOffChainRefsNotRegisteredReverts() public {
        vm.expectRevert(abi.encodeWithSignature("NotRegistered()"));
        digitalIdentity.getOffChainRefs(otherUser);
    }

    function testIsUserRegistered() public {
        assertEq(digitalIdentity.isUserRegistered(user), false);

        vm.prank(user);
        digitalIdentity.registerUser(hashedIdentity, credit, income, debt);

        assertEq(digitalIdentity.isUserRegistered(user), true);
    }
}
