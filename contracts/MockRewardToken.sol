// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IRewardToken.sol";

contract MockRewardToken is IRewardToken {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external override {
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}
