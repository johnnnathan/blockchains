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

        allowedDataTypes.push("email");
        allowedDataTypes.push("phone");

        // Create addresses
        for (uint256 i = 0; i < NUM_USERS; i++) {
            users.push(address(uint160(i + 1)));
        }


        // Unique User Registration
        uint256 gasBefore = gasleft();

        for (uint256 i = 0; i < NUM_USERS; i++) {
            vm.prank(users[i]);

            // Unique identity string
            bytes32 hashedIdentity = keccak256(
                abi.encodePacked("user-", i, "-unique-identity")
            );

            
            string memory creditGroup = string(
                abi.encodePacked("CREDIT-", uint256(i % 5) + 65) // 65 = 'A'
            );
            bytes32 credit = keccak256(bytes(creditGroup));

            
            string[3] memory incomes = ["LOW", "MID", "HIGH"];
            bytes32 income = keccak256(bytes(incomes[i % 3]));

            
            string[3] memory debts = ["LOW", "MID", "HIGH"];
            bytes32 debt = keccak256(bytes(debts[(i + 1) % 3]));

            digitalIdentity.registerUser(hashedIdentity, credit, income, debt);
        }

        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Total gas: registerUser() for 50 users", gasUsed);
        emit log_named_uint("Average gas: registerUser()", gasUsed / NUM_USERS);


        // Measure gas: Consent Creation
        gasBefore = gasleft();
        for (uint256 i = 0; i < NUM_USERS - 1; i++) {
            vm.prank(users[i]);
            consentManager.setConsent(users[i + 1], allowedDataTypes, 30);
        }
        gasUsed = gasBefore - gasleft();
        emit log_named_uint("Total gas: setConsent() for 49 users", gasUsed);
        emit log_named_uint("Average gas: setConsent()", gasUsed / (NUM_USERS - 1));
    }

    function testAllUsersAccessDataAndRewards() public {
        uint256 totalPermitted = 0;


        // Measure gas: Data Access 
        uint256 gasBefore = gasleft();

        for (uint256 i = 1; i < NUM_USERS; i++) {
            vm.prank(users[i]);
            bool permitted = dataSharing.accessData(users[i - 1], "email");
            if (permitted) totalPermitted++;
        }

        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Total gas: accessData() for 49 calls", gasUsed);
        emit log_named_uint("Average gas: accessData()", gasUsed / (NUM_USERS - 1));

        assertEq(totalPermitted, NUM_USERS - 1);

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
        // Mint tokens (not timed)
        address fakeManager = address(999);
        rewardToken = new MockRewardToken();
        for (uint256 i = 0; i < NUM_USERS; i++) {
            vm.prank(fakeManager);
            rewardToken.mint(users[i], 1 ether);
        }

        // Measure gas: Token transfers
        uint256 gasBefore = gasleft();
        for (uint256 i = 0; i < NUM_USERS - 1; i++) {
            vm.prank(users[i]);
            rewardToken.transfer(users[i + 1], 0.1 ether);
        }
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Total gas: token transfers (49 transfers)", gasUsed);
        emit log_named_uint("Average gas: rewardToken.transfer()", gasUsed / (NUM_USERS - 1));

        // Verify balances
        for (uint256 i = 0; i < NUM_USERS; i++) {
            uint256 expected = 1 ether;

            if (i > 0) expected += 0.1 ether;
            if (i < NUM_USERS - 1) expected -= 0.1 ether;

            uint256 actual = rewardToken.balanceOf(users[i]);

            if (actual != expected) {
                emit log_named_uint("Balance mismatch expected", expected);
                emit log_named_uint("Balance mismatch actual", actual);
            }

            assertEq(actual, expected, "Incorrect balance for user");
        }
    }
}
