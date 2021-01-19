//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

contract eventModule {
    /// @dev Events for user actions
    event Deposit(address userAddr, uint256 amount, uint256 userDeposit, uint256 totalDeposit);
    event Withdraw(address userAddr, uint256 amount, uint256 userDeposit, uint256 totalDeposit);
    event Claim(address userAddr, uint256 amount);
    event UpdateRewardParams(uint256 atBlockNumber, uint256 rewardPerBlock, uint256 decrementUnitPerBlock);

    /// @dev Events for admin actions
    event ClaimLock(bool lock);
    event WithdrawLock(bool lock);
    event SetRewardParams(uint256 rewardPerBlock, uint256 decrementUnitPerBlock);
    event RegisterRewardParams(uint256 atBlockNumber, uint256 rewardPerBlock, uint256 decrementUnitPerBlock);
    event DeleteRegisterRewardParams(uint256 index, uint256 atBlockNumber, uint256 rewardPerBlock, uint256 decrementUnitPerBlock, uint256 arrayLen);
}