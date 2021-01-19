//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./safeMath.sol";
import "./storageModule.sol";
import "./eventModule.sol";

/**
 * @title Liquidity staking service contracts (internal)
 * @notice Implement the basic functions for staking and reward distribution
 * @dev All functions are internal.
 */
contract internalModule is storageModule, eventModule, safeMathModule {
    /**
     * @notice Deposit the Contribution Tokens
     * @param userAddr The user address of the Contribution Tokens
     * @param amount The amount of the Contribution Tokens
     */
    function _deposit(address userAddr, uint256 amount) internal {
        Account memory user = accounts[userAddr];
        uint256 totalDeposit = totalDeposited;

        user.deposited = safeAdd(user.deposited, amount);
        accounts[userAddr].deposited = user.deposited;
        totalDeposit = safeAdd(totalDeposited, amount);
        totalDeposited = totalDeposit;

        if(amount > 0) {
            /// @dev transfer the Contribution Toknes to this contract.
            emit Deposit(userAddr, amount, user.deposited, totalDeposit);
            lpErc.transferFrom(userAddr, address(this), amount);
        }
    }

    /**
     * @notice Withdraw the Contribution Tokens
     * @param userAddr The user address of the Contribution Tokens
     * @param amount The amount of the Contribution Tokens
     */
    function _withdraw(address userAddr, uint256 amount) internal {
        Account memory user = accounts[userAddr];
        uint256 totalDeposit = totalDeposited;
        require(user.deposited >= amount, "not enough user Deposit");

        user.deposited = safeSub(user.deposited, amount);
        accounts[userAddr].deposited = user.deposited;
        totalDeposit = safeSub(totalDeposited, amount);
        totalDeposited = totalDeposit;

        if(amount > 0) {
            /// @dev transfer the Contribution Tokens from this contact.
            emit Withdraw(userAddr, amount, user.deposited, totalDeposit);
            lpErc.transfer(userAddr, amount);
        }
    }

    /**
     * @notice Calculate current reward
     * @dev This function is called whenever the balance of the Contribution
       Tokens of the user.
     * @param userAddr The user address of the Contribution and Reward Tokens
     */
    function _redeemAll(address userAddr) internal {
        Account memory user = accounts[userAddr];

        uint256 newRewardLane = _updateRewardLane();

        uint256 distance = safeSub(newRewardLane, user.pointOnLane);
        uint256 rewardAmount = expMul(user.deposited, distance);

        if(user.pointOnLane != newRewardLane) accounts[userAddr].pointOnLane = newRewardLane;
        if(rewardAmount != 0) accounts[userAddr].rewardAmount = safeAdd(user.rewardAmount, rewardAmount);
    }

    /**
     * @notice Claim the Reward Tokens
     * @dev Transfer all reward the user has earned at once.
     * @param userAddr The user address of the Reward Tokens
     */
    function _rewardClaim(address userAddr) internal {
        Account memory user = accounts[userAddr];

        if(user.rewardAmount != 0) {
            uint256 amount = user.rewardAmount;
            accounts[userAddr].rewardAmount = 0;

            /// @dev transfer the Reward Tokens from this contract.
            emit Claim(userAddr, amount);
            rewardErc.transfer(userAddr, amount);
        }
    }

    /**
     * @notice Update the reward lane value upto ths currnet moment (block)
     * @dev This function should care the "reward velocity points," at which the
       parameters of reward distribution are changed.
     * @return The current (calculated) reward lane value
     */
    function _updateRewardLane() internal returns (uint256) {
        /// @dev Set up memory variables used for calculation temporarily.
        UpdateRewardLaneModel memory vars;

        vars.len = registeredPoints.length;
        vars.memTotalDeposit = totalDeposited;

        vars.tmpPassedPoint = vars.memPassedPoint = passedPoint;

        vars.memThisBlockNum = block.number;
        vars.tmpLastBlockNum = vars.memLastBlockNum = lastBlockNum;

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
                emit UpdateRewardParams(point.blockNumber, point.rewardPerBlock, point.decrementUnitPerBlock);
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

        /**
         * @dev Update the reward lane parameters with the tmp variables.
         */
        if(vars.memLastBlockNum != vars.tmpLastBlockNum) lastBlockNum = vars.memThisBlockNum;
        if(vars.memPassedPoint != vars.tmpPassedPoint) passedPoint = vars.tmpPassedPoint;
        if(vars.memRewardLane != vars.tmpRewardLane) rewardLane = vars.tmpRewardLane;
        if(vars.memRewardPerBlock != vars.tmpRewardPerBlock) rewardPerBlock = vars.tmpRewardPerBlock;
        if(vars.memDecrementUnitPerBlock != vars.tmpDecrementUnitPerBlock) decrementUnitPerBlock = vars.tmpDecrementUnitPerBlock;

        return vars.tmpRewardLane;
    }

    /**
     * @notice Calculate a new reward lane value with the given parameters
     * @param _rewardLane The previous reward lane value
     * @param _totalDeposit Thte total deposit amount of the Contribution Tokens
     * @param _rewardPerBlock The reward token amount per a block
     * @param _decrementUnitPerBlock The decerement amount of the reward token per a block
     */
    function _calcNewRewardLane(
        uint256 _rewardLane,
        uint256 _totalDeposit,
        uint256 _rewardPerBlock,
        uint256 _decrementUnitPerBlock,
        uint256 delta) internal pure returns (uint256, uint256) {
            if(_totalDeposit != 0) {
                uint256 distance = expMul( _meanOfInactiveLane(_rewardPerBlock, delta, _decrementUnitPerBlock), safeMul( expDiv(one, _totalDeposit), delta) );
                uint256 newRewardLane = safeAdd(_rewardLane, distance);
                uint256 newRewardPerBlock = _getNewRewardPerBlock(_rewardPerBlock, _decrementUnitPerBlock, delta);
                return (newRewardLane, newRewardPerBlock);
            }
            return (_rewardLane, _rewardPerBlock);
    }

    /**
     * @notice Register a new reward velocity point
     * @dev We assume that reward velocity points are stored in order of block
       number. Namely, registerPoints is always a sorted array.
     * @param _blockNumber The block number for the point.
     * @param _rewardPerBlock The reward token amount per a block
     * @param _decrementUnitPerBlock The decerement amount of the reward token per a block
     */
    function _registerRewardVelocity(uint256 _blockNumber, uint256 _rewardPerBlock, uint256 _decrementUnitPerBlock) internal {
        RewardVelocityPoint memory varPoint = RewardVelocityPoint(_blockNumber, _rewardPerBlock, _decrementUnitPerBlock);
        emit RegisterRewardParams(_blockNumber, _rewardPerBlock, _decrementUnitPerBlock);
        registeredPoints.push(varPoint);
    }

    /**
     * @notice Delete a existing reward velocity point
     * @dev We assume that reward velocity points are stored in order of block
       number. Namely, registerPoints is always a sorted array.
     * @param _index The index number of deleting point in state array.
     */
    function _deleteRegisteredRewardVelocity(uint256 _index) internal {
        uint256 len = registeredPoints.length;
        require(len != 0 && _index < len, "error: no elements in registeredPoints");
        RewardVelocityPoint memory point = registeredPoints[_index];
        emit DeleteRegisterRewardParams(_index, point.blockNumber, point.rewardPerBlock, point.decrementUnitPerBlock, len-1);
        for(uint i=_index; i<len-1; i++) {
            registeredPoints[i] = registeredPoints[i+1];
        }
        registeredPoints.pop();
    }

    /**
     * @notice Set paramaters for the reward distribution
     * @param _rewardPerBlock The reward token amount per a block
     * @param _decrementUnitPerBlock The decerement amount of the reward token per a block
     */
    function _setParams(uint256 _rewardPerBlock, uint256 _decrementUnitPerBlock) internal {
        emit SetRewardParams(_rewardPerBlock, _decrementUnitPerBlock);
        rewardPerBlock = _rewardPerBlock;
        decrementUnitPerBlock = _decrementUnitPerBlock;
    }

    /**
     * @return the avaerage of the RewardLance of the inactive (i.e., no-action)
       periods.
    */
    function _meanOfInactiveLane(uint256 a, uint256 n, uint256 d) internal pure returns (uint256) {
        /**
        @dev return Sn / n,
                where Sn = ( (n{2*a + (n-1)d}) / 2 )
            == ( (2na + (n-1)d) / 2 ) / n
            caveat: use safeSub() to avoid the case that d is negative
        */
        if (n > 0 )
            return safeDiv(safeSub( safeMul(safeMul(2,a), n), safeMul(safeMul(n, safeSub(n,1)), d)), safeMul(2, n));
        else
            return 0;
    }

    function _getNewRewardPerBlock(uint256 before, uint256 dec, uint256 delta) internal pure returns (uint256) {
        uint256 tmp = safeMul(dec, delta);
        if (before > tmp)
            return safeSub(before, tmp);
        else
            return 0;
    }

    function _setClaimLock(bool lock) internal {
        emit ClaimLock(lock);
        claimLock = lock;
    }

    function _setWithdrawLock(bool lock) internal {
        emit WithdrawLock(lock);
        withdrawLock = lock;
    }
}