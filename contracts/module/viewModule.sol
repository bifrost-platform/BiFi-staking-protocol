//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./internalModule.sol";

contract viewModule is internalModule {
    function modelInfo() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (rewardPerBlock, decrementUnitPerBlock, rewardLane, lastBlockNum, totalDeposited);
    }

    function getParams() external view returns (uint256, uint256, uint256, uint256) {
        return (rewardPerBlock, rewardLane, lastBlockNum, totalDeposited);
    }

    function getRegisteredPointLength() external view returns (uint256) {
        return registeredPoints.length;
    }

    function getRegisteredPoint(uint256 index) external view returns (uint256, uint256, uint256) {
        RewardVelocityPoint memory point = registeredPoints[index];
        return (point.blockNumber, point.rewardPerBlock, point.decrementUnitPerBlock);
    }

    function userInfo(address userAddr) external view returns (uint256, uint256) {
        Account memory user = accounts[userAddr];
        return (user.deposited, user.pointOnLane);
    }
}