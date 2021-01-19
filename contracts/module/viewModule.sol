// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import "./internalModule.sol";

/**
 * @title BiFi's Reward Distribution View Contract
 * @notice Implements the view functions for support front-end
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract viewModule is internalModule {
    function marketInformation(uint256 _fromBlockNumber, uint256 _toBlockNumber) external view returns (
        uint256 rewardStartBlockNumber,
        uint256 distributedAmount,
        uint256 totalDeposit,
        uint256 poolRate
        )
    {
        if(rewardPerBlock == 0) rewardStartBlockNumber = registeredPoints[0].blockNumber;
        else rewardStartBlockNumber = registeredPoints[0].blockNumber;

        distributedAmount = _redeemAllView(address(0));

        totalDeposit = totalDeposited;

        poolRate = getPoolRate(address(0), _fromBlockNumber, _toBlockNumber);

        return (
            rewardStartBlockNumber,
            distributedAmount,
            totalDeposit,
            poolRate
        );
    }

    function userInformation(address userAddr, uint256 _fromBlockNumber, uint256 _toBlockNumber) external view returns (
        uint256 stakedTokenAmount,
        uint256 rewardStartBlockNumber,
        uint256 claimStartBlockNumber,
        uint256 earnedTokenAmount,
        uint256 poolRate
        )
    {
        Account memory user = accounts[userAddr];

        stakedTokenAmount = user.deposited;

        if(rewardPerBlock == 0) rewardStartBlockNumber = registeredPoints[0].blockNumber;
        else rewardStartBlockNumber = registeredPoints[0].blockNumber;

        earnedTokenAmount = _redeemAllView(userAddr);

        poolRate = getPoolRate(userAddr, _fromBlockNumber, _toBlockNumber);

        return (stakedTokenAmount, rewardStartBlockNumber, claimStartBlockNumber, earnedTokenAmount, poolRate);
    }

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
        if(fromBlockNumber == 0){
            vars.tmpPassedPoint = vars.memPassedPoint = 0;

            vars.memThisBlockNum = block.number;
            // vars.tmpLastBlockNum = vars.memLastBlockNum = lastBlockNum;
            vars.tmpLastBlockNum = vars.memLastBlockNum = 0;
            vars.tmpRewardLane = vars.memRewardLane = 0;
            vars.tmpRewardPerBlock = vars.memRewardPerBlock = 0;
            vars.tmpDecrementUnitPerBlock = vars.memDecrementUnitPerBlock = 0;
        } else {
            vars.tmpPassedPoint = vars.memPassedPoint = passedPoint;
            vars.memThisBlockNum = block.number;
            // vars.tmpLastBlockNum = vars.memLastBlockNum = lastBlockNum;
            vars.tmpLastBlockNum = vars.memLastBlockNum = fromBlockNumber;

            vars.tmpRewardLane = vars.memRewardLane = rewardLane;
            vars.tmpRewardPerBlock = vars.memRewardPerBlock = rewardPerBlock;
            vars.tmpDecrementUnitPerBlock = vars.memDecrementUnitPerBlock = decrementUnitPerBlock;
        }

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

    function getPoolRate(address userAddr, uint256 fromBlockNumber, uint256 toBlockNumber) internal view returns (uint256) {
        UpdateRewardLaneModel memory vars;

        vars.len = registeredPoints.length;
        vars.memTotalDeposit = totalDeposited;

        vars.tmpLastBlockNum = vars.memLastBlockNum = fromBlockNumber;
        (vars.memPassedPoint, vars.memRewardPerBlock, vars.memDecrementUnitPerBlock) = getParamsByBlockNumber(fromBlockNumber);
        vars.tmpPassedPoint = vars.memPassedPoint;
        vars.tmpRewardPerBlock = vars.memRewardPerBlock;
        vars.tmpDecrementUnitPerBlock = vars.memDecrementUnitPerBlock;

        vars.memThisBlockNum = toBlockNumber;
        vars.tmpRewardLane = vars.memRewardLane = 0;

        for(uint256 i=vars.memPassedPoint; i<vars.len; i++) {
            RewardVelocityPoint memory point = registeredPoints[i];

            if(vars.tmpLastBlockNum < point.blockNumber && point.blockNumber <= vars.memThisBlockNum) {
                vars.tmpPassedPoint = i+1;
                vars.tmpBlockDelta = safeSub(point.blockNumber, vars.tmpLastBlockNum);
                (vars.tmpRewardLane, vars.tmpRewardPerBlock) =
                _calcNewRewardLane(
                    vars.tmpRewardLane,
                    vars.memTotalDeposit,
                    vars.tmpRewardPerBlock,
                    vars.tmpDecrementUnitPerBlock,
                    vars.tmpBlockDelta);

                vars.tmpLastBlockNum = point.blockNumber;
                vars.tmpRewardPerBlock = point.rewardPerBlock;
                vars.tmpDecrementUnitPerBlock = point.decrementUnitPerBlock;

            } else {
                break;
            }
        }

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

        Account memory user;
        if( userAddr != address(0) ) user = accounts[userAddr];
        else user = Account(vars.memTotalDeposit, 0, 0);

        return safeDiv(expMul(user.deposited, vars.tmpRewardLane), safeSub(toBlockNumber, fromBlockNumber));
    }

    function getParamsByBlockNumber(uint256 _blockNumber) internal view returns (uint256, uint256, uint256) {
        uint256 _rewardPerBlock; uint256 _decrement;
        uint256 i;

        uint256 tmpthisPoint;

        uint256 pointLength = registeredPoints.length;
        if( pointLength > 0 ) {
            for(i = 0; i < pointLength; i++) {
                RewardVelocityPoint memory point = registeredPoints[i];
                if(_blockNumber >= point.blockNumber && 0 != point.blockNumber) {
                    tmpthisPoint = i;
                    _rewardPerBlock = point.rewardPerBlock;
                    _decrement = point.decrementUnitPerBlock;
                } else if( 0 == point.blockNumber ) continue;
                else break;
            }
        }
        RewardVelocityPoint memory point = registeredPoints[tmpthisPoint];
        _rewardPerBlock = point.rewardPerBlock;
        _decrement = point.decrementUnitPerBlock;
        if(_blockNumber > point.blockNumber) {
            _rewardPerBlock = safeSub(_rewardPerBlock, safeMul(_decrement, safeSub(_blockNumber, point.blockNumber) ) );
        }
        return (i, _rewardPerBlock, _decrement);
    }

    function getUserPoolRate(address userAddr, uint256 fromBlockNumber, uint256 toBlockNumber) external view returns (uint256) {
        return getPoolRate(userAddr, fromBlockNumber, toBlockNumber);
    }

    function getModelPoolRate(uint256 fromBlockNumber, uint256 toBlockNumber) external view returns (uint256) {
        return getPoolRate(address(0), fromBlockNumber, toBlockNumber);
    }
}