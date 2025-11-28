// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Types

library Types {
    enum DataCategory {
        CreditScore,
        IncomeVerification,
        DebtToIncome,
        PaymentHistory,
        AccountAge
    }

    struct CreditProfile {
        bytes32 hashedCreditTier;
        bytes32 hashedIncomeTier;
        bytes32 hashedDebtRatio;
        uint256 lastUpdated;
        bool isActive;
    }

    struct User {
        address userAddress;
        bytes32 hashedIdentity;
        CreditProfile creditProfile;
        string[] offChainRefs;
        uint256 registrationTime;
        bool isRegistered;
    }
}