
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./RewardToken.sol";

contract RewardTokenTest is Test {
    RewardToken rewardToken;
    address consentManager = address(1);
    address user = address(2);
    address otherUser = address(3);

    function setUp() public {
        rewardToken = new RewardToken("Reward", "RWD", 18, consentManager);
    }

    function testMintByConsentManager() public {
        // Simulate call from consentManager
        vm.prank(consentManager);
        uint256 gasBefore = gasleft();
        rewardToken.mint(user, 1 ether);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for mint", gasUsed);

        uint256 balance = rewardToken.balanceOf(user);
        assertEq(balance, 1 ether);
    }

    function testMintByNonConsentManagerReverts() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("NotConsentManager()"));
        rewardToken.mint(user, 1 ether);
    }

    function testMintToZeroAddressReverts() public {
        vm.prank(consentManager);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        rewardToken.mint(address(0), 1 ether);
    }

    function testTransfer() public {
        vm.prank(consentManager);
        rewardToken.mint(user, 1 ether);

        vm.prank(user);
        uint256 gasBefore = gasleft();
        bool success = rewardToken.transfer(otherUser, 0.5 ether);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Gas used for transfer", gasUsed);

        assertTrue(success);
        assertEq(rewardToken.balanceOf(user), 0.5 ether);
        assertEq(rewardToken.balanceOf(otherUser), 0.5 ether);
    }

    function testTransferInsufficientBalanceReverts() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        rewardToken.transfer(otherUser, 1 ether);
    }

    function testTransferToZeroAddressReverts() public {
        vm.prank(consentManager);
        rewardToken.mint(user, 1 ether);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        rewardToken.transfer(address(0), 0.5 ether);
    }

    function testConstructorZeroConsentManagerReverts() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        new RewardToken("Reward", "RWD", 18, address(0));
    }
}
