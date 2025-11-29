
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./DataSharing.sol";
import "./ConsentManager.sol";
import "./IRewardToken.sol";
import "./DataTypes.sol";
import "./MockRewardToken.sol";


contract LargeScaleIntegrationTest is Test {
    ConsentManager consentManager;
    MockRewardToken rewardToken;
    DataSharing dataSharing;

    uint256 constant NUM_USERS = 50;
    address[] users;

    string[] allowedDataTypes;

    function setUp() public {
        rewardToken = new MockRewardToken();
        consentManager = new ConsentManager(address(rewardToken));
        dataSharing = new DataSharing(address(consentManager));

        // Prepare allowed data types
        allowedDataTypes.push("email");
        allowedDataTypes.push("phone");

        // Create NUM_USERS test addresses
        for (uint256 i = 0; i < NUM_USERS; i++) {
            users.push(address(uint160(i + 1))); // deterministic addresses: 1..NUM_USERS
        }

        // Each user grants consent to the next user
        for (uint256 i = 0; i < NUM_USERS - 1; i++) {
            address owner = users[i];
            address requester = users[i + 1];
            vm.prank(owner);
            consentManager.setConsent(requester, allowedDataTypes, 30);
        }
    }

    function testAllUsersAccessData() public {
        uint256 totalPermitted = 0;

        // Each user tries to access the previous user's data
        for (uint256 i = 1; i < NUM_USERS; i++) {
            address requester = users[i];
            address owner = users[i - 1];

            vm.prank(requester);
            bool permitted = dataSharing.accessData(owner, "email");

            if (permitted) {
                totalPermitted++;
            }
        }

        emit log_named_uint("Total permitted accesses", totalPermitted);

        // Assert that all accesses that should be permitted actually are
        assertEq(totalPermitted, NUM_USERS - 1);

        // Check rewards: each owner got 1 ether minted for granting consent
        for (uint256 i = 0; i < NUM_USERS - 1; i++) {
            assertEq(rewardToken.balanceOf(users[i]), 1 ether);
        }
    }

    function testUnauthorizedAccessFails() public {
        // The last user (users[NUM_USERS-1]) has no one granting consent to them
        address unauthorized = users[NUM_USERS - 1];
        address owner = users[0];

        vm.prank(unauthorized);
        bool permitted = dataSharing.accessData(owner, "phone");
        assertEq(permitted, false);
    }
}
