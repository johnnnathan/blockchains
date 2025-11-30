// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./DataSharing.sol";
import "./ConsentManager.sol";
import "./IRewardToken.sol";
import "./MockRewardToken.sol";
import "./DigitalIdentity.sol";

contract LargeScaleIntegrationTest is Test {
    ConsentManager consentManager;
    MockRewardToken rewardToken;
    DataSharing dataSharing;
    DigitalIdentity digitalIdentity;

    uint256 constant NUM_USERS = 50;
    address[] users;

    string[] allowedDataTypes;

    function setUp() public {
        rewardToken = new MockRewardToken();
        consentManager = new ConsentManager(address(rewardToken));
        dataSharing = new DataSharing(address(consentManager));
        digitalIdentity = new DigitalIdentity();

        // Prepare allowed data types
        allowedDataTypes.push("email");
        allowedDataTypes.push("phone");

        // Create NUM_USERS test addresses
        for (uint256 i = 0; i < NUM_USERS; i++) {
            users.push(address(uint160(i + 1)));
        }

        // Each user registers a digital identity
        for (uint256 i = 0; i < NUM_USERS; i++) {
            vm.prank(users[i]);
            bytes32 hashedIdentity = keccak256(abi.encodePacked("user", i));
            bytes32 credit = keccak256(abi.encodePacked("A"));
            bytes32 income = keccak256(abi.encodePacked("HIGH"));
            bytes32 debt = keccak256(abi.encodePacked("LOW"));
            digitalIdentity.registerUser(hashedIdentity, credit, income, debt);
        }

        // Each user grants consent to the next user
        for (uint256 i = 0; i < NUM_USERS - 1; i++) {
            vm.prank(users[i]);
            consentManager.setConsent(users[i + 1], allowedDataTypes, 30);
        }
    }

    function testAllUsersAccessDataAndRewards() public {
        uint256 totalPermitted = 0;

        // Each user tries to access the previous user's data
        for (uint256 i = 1; i < NUM_USERS; i++) {
            vm.prank(users[i]);
            bool permitted = dataSharing.accessData(users[i - 1], "email");

            if (permitted) {
                totalPermitted++;
            }
        }

        emit log_named_uint("Total permitted accesses", totalPermitted);
        assertEq(totalPermitted, NUM_USERS - 1);

        // Check rewards for granting consent
        for (uint256 i = 0; i < NUM_USERS - 1; i++) {
            assertEq(rewardToken.balanceOf(users[i]), 1 ether);
        }
    }

    function testUnauthorizedAccessFails() public {
        address unauthorized = users[NUM_USERS - 1];
        address owner = users[0];

        vm.prank(unauthorized);
        bool permitted = dataSharing.accessData(owner, "phone");
        assertEq(permitted, false);
    }

    function testTokenTransfers() public {
        // Mint some tokens first
        for (uint256 i = 0; i < NUM_USERS; i++) {
            vm.prank(users[i]);
            rewardToken.mint(users[i], 1 ether);
        }

        // Let each user transfer 0.1 ether to the next user
        for (uint256 i = 0; i < NUM_USERS - 1; i++) {
            vm.prank(users[i]);
            rewardToken.transfer(users[i + 1], 0.1 ether);
        }

        // Check final balances for a few users
        assertEq(rewardToken.balanceOf(users[0]), 0.9 ether);
        assertEq(rewardToken.balanceOf(users[1]), 1.2 ether); // 1 + 0.1 from user[0]
        assertEq(rewardToken.balanceOf(users[NUM_USERS - 1]), 1.1 ether); // received 0.1 from previous
    }
}
