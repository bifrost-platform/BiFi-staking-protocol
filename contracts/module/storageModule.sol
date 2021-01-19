// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import "../ERC20.sol";

/**
 * @title BiFi's Reward Distribution Storage Contract
 * @notice Define the basic Contract State
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract storageModule {
    address public owner;

    bool public claimLock;
    bool public withdrawLock;

    uint256 public rewardPerBlock;
    uint256 public decrementUnitPerBlock;
    uint256 public rewardLane;

    uint256 public lastBlockNum;
    uint256 public totalDeposited;

    ERC20 public lpErc; ERC20 public rewardErc;

    mapping(address => Account) public accounts;

    uint256 public passedPoint;
    RewardVelocityPoint[] public registeredPoints;

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