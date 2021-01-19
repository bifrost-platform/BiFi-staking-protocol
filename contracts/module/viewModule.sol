//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./internalModule.sol";

contract viewModule is internalModule {
    uint256 constant blockInterval = 15;

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

    function userInfo(address userAddr) external view returns (uint256, uint256, uint256) {
        Account memory user = accounts[userAddr];
        uint256 earnedRewardAmount = _redeemAllView(userAddr);

        return (user.deposited, user.pointOnLane, earnedRewardAmount);
    }

    function distributionInfo() external view returns (uint256, uint256, uint256) {
        uint256 totalDistributedRewardAmount_now = _distributedRewardAmountView();
        return (rewardPerBlock, decrementUnitPerBlock, totalDistributedRewardAmount_now);
    }

    function _distributedRewardAmountView() internal view returns (uint256) {
        return _redeemAllView( address(0) );
    }

    function _redeemAllView(address userAddr) internal view returns (uint256) {
        Account memory user;
        uint256 newRewardLane;
        if( userAddr != address(0) ) {
            user = accounts[userAddr];
            newRewardLane = _updateRewardLaneView(lastBlockNum);
        } else {
            user = Account(totalDeposited, 0, 0);
            newRewardLane = _updateRewardLaneView(0);
        }

        uint256 distance = safeSub(newRewardLane, user.pointOnLane);
        uint256 rewardAmount = expMul(user.deposited, distance);

        return safeAdd(user.rewardAmount, rewardAmount);
    }

    function _updateRewardLaneView(uint256 fromBlockNumber) internal view returns (uint256) {
        /// @dev Set up memory variables used for calculation temporarily.
        UpdateRewardLaneModel memory vars;

        vars.len = registeredPoints.length;
        vars.memTotalDeposit = totalDeposited;

        // vars.tmpPassedPoint = vars.memPassedPoint = passedPoint;
        vars.tmpPassedPoint = vars.memPassedPoint = 0;

        vars.memThisBlockNum = block.number;
        // vars.tmpLastBlockNum = vars.memLastBlockNum = lastBlockNum;
        vars.tmpLastBlockNum = vars.memLastBlockNum = fromBlockNumber;

        vars.tmpRewardLane = vars.memRewardLane = rewardLane;
        vars.tmpRewardPerBlock = vars.memRewardPerBlock = rewardPerBlock;
        vars.tmpDecrementUnitPerBlock = vars.memDecrementUnitPerBlock = decrementUnitPerBlock;

        for(uint256 i=vars.memPassedPoint; i<vars.len; i++) {
            RewardVelocityPoint memory point = registeredPoints[i];
            /**
             * @dev Check whether this reward velocity point is valid and has
               not applied yet.
             */
            if(vars.tmpLastBlockNum < point.blockNumber && point.blockNumber <= vars.memThisBlockNum) {
                vars.tmpPassedPoint = i+1;
                /// @dev Update the reward lane with the tmp variables
                vars.tmpBlockDelta = safeSub(point.blockNumber, vars.tmpLastBlockNum);
                (vars.tmpRewardLane, vars.tmpRewardPerBlock) =
                _calcNewRewardLane(
                    vars.tmpRewardLane,
                    vars.memTotalDeposit,
                    vars.tmpRewardPerBlock,
                    vars.tmpDecrementUnitPerBlock,
                    vars.tmpBlockDelta);

                /// @dev Update the tmp variables with this reward velocity point.
                vars.tmpLastBlockNum = point.blockNumber;
                vars.tmpRewardPerBlock = point.rewardPerBlock;
                vars.tmpDecrementUnitPerBlock = point.decrementUnitPerBlock;
                /**
                 * @dev Notify the update of the parameters (by passing the
                   reward velocity points)
                 */
            } else {
                /// @dev sorted array, exit eariler without accessing future points.
                break;
            }
        }

        /**
         * @dev Update the reward lane for the remained period between the
           latest velocity point and this moment (block)
         */
        if(vars.memThisBlockNum > vars.tmpLastBlockNum) {
            vars.tmpBlockDelta = safeSub(vars.memThisBlockNum, vars.tmpLastBlockNum);
            vars.tmpLastBlockNum = vars.memThisBlockNum;
            (vars.tmpRewardLane, vars.tmpRewardPerBlock) =
            _calcNewRewardLane(
                vars.tmpRewardLane,
                vars.memTotalDeposit,
                vars.tmpRewardPerBlock,
                vars.tmpDecrementUnitPerBlock,
                vars.tmpBlockDelta);
        }

        return vars.tmpRewardLane;
    }
}