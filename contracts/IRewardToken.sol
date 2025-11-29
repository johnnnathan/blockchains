// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Minimal interface for RewardToken
interface IRewardToken {
    /// @notice Returns the token balance of the account
    /// @param account The address of the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers amount tokens from caller to to
    /// @param to The recipient address
    /// @param amount The amount of tokens to transfer
    /// @return True if successful transfer
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Mints amount tokens to to
    /// @dev Should only be callable by the ConsentManager contract
    /// @param to Recipient address
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external;
}

