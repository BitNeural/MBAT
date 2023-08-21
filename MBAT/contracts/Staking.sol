// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MBATToken.sol";

contract Staking {
    MBATToken private token;

    struct Staker {
        uint256 balance;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => Staker) public stakers;

    event TokensStaked(address indexed staker, uint256 amount, uint256 endTime);
    event TokensUnstaked(address indexed staker, uint256 amount);

    constructor(address tokenAddress) {
        token = MBATToken(tokenAddress);
    }

    modifier onlyStaker() {
        require(stakers[msg.sender].balance > 0, "Not a staker");
        _;
    }

    function stakeTokens(uint256 amount, uint256 duration) external {
        require(amount > 0, "Amount must be greater than zero");
        require(duration > 0, "Duration must be greater than zero");
        require(token.balanceOf(msg.sender) >= amount, "Insufficient token balance");

        uint256 endTime = block.timestamp + duration;
        token.transferFrom(msg.sender, address(this), amount);

        stakers[msg.sender].balance += amount;
        stakers[msg.sender].startTime = block.timestamp;
        stakers[msg.sender].endTime = endTime;

        emit TokensStaked(msg.sender, amount, endTime);
    }

    function unstakeTokens() external onlyStaker {
        require(block.timestamp >= stakers[msg.sender].endTime, "Staking duration not completed");

        uint256 amount = stakers[msg.sender].balance;
        stakers[msg.sender].balance = 0;

        token.transfer(msg.sender, amount);

        emit TokensUnstaked(msg.sender, amount);
    }

    function getStakerInfo(address staker) external view returns (uint256 balance, uint256 startTime, uint256 endTime) {
        Staker memory stakerInfo = stakers[staker];
        return (stakerInfo.balance, stakerInfo.startTime, stakerInfo.endTime);
    }
}