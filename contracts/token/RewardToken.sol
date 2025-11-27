// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IRewardToken.sol";

/// @title RewardToken implementation
/// @notice Minimal ERC20-like token for consent rewards. Only ConsentManager can mint

contract RewardToken is IRewardToken {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;
    mapping(address => uint256) private balances;

    address public consentManager;

    event Transfer(address indexed from, address indexed to, uint256 value);

    error NotConsentManager();
    error ZeroAddress();
    error InsufficientBalance();

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address consentManager_
    ) {
        if (consentManager_ == address(0)) {
            revert ZeroAddress();
        }
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        consentManager = consentManager_;
    }

    /// @inheritdoc IRewardToken

    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    /// @inheritdoc IRewardToken
    function mint(address to, uint256 amount) external override {
        if (msg.sender != consentManager) {
            revert NotConsentManager();
        }
        if (to == address(0)) {
            revert ZeroAddress();
        }

        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @inheritdoc IRewardToken
    function transfer(address to, uint256 amount) external override returns (bool) {
        if (to == address(0)) {
            revert ZeroAddress();
        }

        uint256 senderBalance = balances[msg.sender];
        if (senderBalance < amount) {
            revert InsufficientBalance();
        }
        balances[msg.sender] = senderBalance - amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }
}