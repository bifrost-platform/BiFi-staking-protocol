//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "../ERC20.sol";

contract storageModule {
    address owner;

    bool claimLock = false;
    bool withdrawLock = false;

    uint256 rewardPerBlock = 0;
    uint256 decrementUnitPerBlock = 0;
    uint256 rewardLane = 0;

    uint256 lastBlockNum = 0;
    uint256 totalDeposited = 0;

    ERC20 lpErc; ERC20 rewardErc;

    mapping(address => Account) accounts;

    uint256 passedPoint;
    RewardVelocityPoint[] registeredPoints;

    struct Account {
        uint256 deposited;
        uint256 pointOnLane;
        uint256 rewardAmount;
    }

    struct RewardVelocityPoint {
        uint256 blockNumber;
        uint256 rewardPerBlock;
        uint256 decrementUnitPerBlock;
    }

    struct UpdateRewardLaneModel {
        uint256 len; uint256 tmpBlockDelta;

        uint256 memPassedPoint; uint256 tmpPassedPoint;

        uint256 memThisBlockNum;
        uint256 memLastBlockNum; uint256 tmpLastBlockNum;

        uint256 memTotalDeposit;

        uint256 memRewardLane; uint256 tmpRewardLane;
        uint256 memRewardPerBlock; uint256 tmpRewardPerBlock;

        uint256 memDecrementUnitPerBlock; uint256 tmpDecrementUnitPerBlock;
    }
}