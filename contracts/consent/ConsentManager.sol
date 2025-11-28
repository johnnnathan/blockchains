// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IConsentManager.sol";
import "../token/IRewardToken.sol";

/// @title ConsentManager
/// @notice Handles creation, revocation, and validation of user consents.
/// @dev RewardToken minting is triggered on consent creation.
contract ConsentManager is IConsentManager {


    IRewardToken public immutable rewardToken;

    uint256 private nextConsentId;

    /// @notice Mapping of consentId => Consent struct
    mapping(uint256 => Consent) private consents;

    /// @notice Mapping of owner address => list of their consent IDs
    mapping(address => uint256[]) private userConsents;


    constructor(address rewardTokenAddress) {
        require(rewardTokenAddress != address(0), "Invalid token address");
        rewardToken = IRewardToken(rewardTokenAddress);
        nextConsentId = 1;
    }


    modifier onlyOwner(uint256 consentId) {
        if (consents[consentId].owner != msg.sender) {
            revert NotConsentOwner();
        }
        _;
    }


    /// @inheritdoc IConsentManager
    function setConsent(
        address requester,
        string[] calldata allowedDataTypes,
        uint256 durationDays
    ) external override {

        if (requester == address(0)) revert InvalidRequester();
        if (durationDays == 0 || durationDays > 90) revert InvalidDuration();
        if (allowedDataTypes.length == 0) revert InvalidDuration();

        uint256 consentId = nextConsentId++;
        uint256 start = block.timestamp;
        uint256 expiry = block.timestamp + (durationDays * 1 days);

        Consent memory c = Consent({
            consentId: consentId,
            owner: msg.sender,
            requester: requester,
            allowedDataTypes: allowedDataTypes,
            startTime: start,
            expiryTime: expiry,
            active: true
        });

        consents[consentId] = c;
        userConsents[msg.sender].push(consentId);

        // Mint reward tokens to user
        rewardToken.mint(msg.sender, 1 ether);

        emit ConsentCreated(consentId, msg.sender, requester);
    }

    /// @inheritdoc IConsentManager
    function revokeConsent(uint256 consentId)
        external
        override
        onlyOwner(consentId)
    {
        Consent storage c = consents[consentId];

        if (!c.active) revert ConsentNotActive();

        c.active = false;

        emit ConsentRevoked(consentId, msg.sender);
    }

    /// @inheritdoc IConsentManager
    function checkConsent(
        address owner,
        address requester,
        string calldata dataType
    ) external view override returns (bool) {

        uint256[] memory ids = userConsents[owner];

        for (uint256 i = 0; i < ids.length; i++) {
            Consent memory c = consents[ids[i]];

            if (
                c.active &&
                c.requester == requester &&
                block.timestamp <= c.expiryTime
            ) {
                // Check allowed data categories
                for (uint256 j = 0; j < c.allowedDataTypes.length; j++) {
                    if (
                        keccak256(bytes(c.allowedDataTypes[j])) ==
                        keccak256(bytes(dataType))
                    ) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /// @inheritdoc IConsentManager
    function getConsent(uint256 consentId)
        external
        view
        override
        returns (Consent memory)
    {
        return consents[consentId];
    }

    /// @inheritdoc IConsentManager
    function getUserConsents(address owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        return userConsents[owner];
    }
}