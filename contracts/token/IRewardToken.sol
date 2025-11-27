// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Minimal interface for RewardToken
interface IRewardToken {
    /// @param account The address of the account
    /// @notice Returns the token balance of the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers @param amount tokens from caller to @param to
    /// @return True if successful transfer
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Mints @param amount tokens to @param to
    /// @dev should only be callable by the ConsentManager contract
    function mint(address to, uint256 amount) external;
}