// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import "./viewModule.sol";

/**
 * @title BiFi's Reward Distribution External Contract
 * @notice Implements the service actions.
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract externalModule is viewModule {
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner: external function access control!");
        _;
    }
    modifier checkClaimLocked() {
        require(!claimLock, "error: claim Locked");
        _;
    }
    modifier checkWithdrawLocked() {
        require(!withdrawLock, "error: withdraw Locked");
        _;
    }

    /**
     * @notice Set the Deposit-Token address
     * @param erc20Addr The address of Deposit Token
     */
    function setERC(address erc20Addr) external onlyOwner {
        lpErc = ERC20(erc20Addr);
    }

    /**
     * @notice Set the Contribution-Token address
     * @param erc20Addr The address of Contribution Token
     */
    function setRE(address erc20Addr) external onlyOwner {
        rewardErc = ERC20(erc20Addr);
    }

    /**
     * @notice Set the reward distribution parameters instantly
     */
    function setParam(uint256 _rewardPerBlock, uint256 _decrementUnitPerBlock) onlyOwner external {
        _setParams(_rewardPerBlock, _decrementUnitPerBlock);
    }

    /**
     * @notice Terminate Contract Distribution
     */
    function modelFinish(uint256 amount) external onlyOwner {
        if( amount != 0) {
            require( rewardErc.transfer(owner, amount), "token error" );
        }
        else {
            require( rewardErc.transfer(owner, rewardErc.balanceOf(address(this))), "token error" );
        }
        delete totalDeposited;
        delete rewardPerBlock;
        delete decrementUnitPerBlock;
        delete rewardLane;
        delete totalDeposited;
        delete registeredPoints;
    }

    /**
     * @notice Transfer the Remaining Contribution Tokens
     */
    function retrieveRewardAmount(uint256 amount) external onlyOwner {
        if( amount != 0) {
            require( rewardErc.transfer(owner, amount), "token error");
        }
        else {
            require( rewardErc.transfer(owner, rewardErc.balanceOf(address(this))), "token error");
        }
    }

    /**
     * @notice Deposit the Contribution Tokens
     * @param amount The amount of the Contribution Tokens
     */
    function deposit(uint256 amount) external {
        address userAddr = msg.sender;
        _redeemAll(userAddr);
        _deposit(userAddr, amount);
    }

    /**
     * @notice Deposit the Contribution Tokens to target user
     * @param userAddr The target user
     * @param amount The amount of the Contribution Tokens
     */
    function depositTo(address userAddr, uint256 amount) external {
        _redeemAll(userAddr);
        _deposit(userAddr, amount);
    }

    /**
     * @notice Withdraw the Contribution Tokens
     * @param amount The amount of the Contribution Tokens
     */
    function withdraw(uint256 amount) checkWithdrawLocked external {
        address userAddr = msg.sender;
        _redeemAll(userAddr);
        _withdraw(userAddr, amount);
    }

    /**
     * @notice Claim the Reward Tokens
     * @dev Transfer all reward the user has earned at once.
     */
    function rewardClaim() checkClaimLocked external {
        address userAddr = msg.sender;
        _redeemAll(userAddr);
        _rewardClaim(userAddr);
    }
    /**
     * @notice Claim the Reward Tokens
     * @param userAddr The targetUser
     * @dev Transfer all reward the target user has earned at once.
     */
    function rewardClaimTo(address userAddr) checkClaimLocked external {
        _redeemAll(userAddr);
        _rewardClaim(userAddr);
    }

    /// @dev Set locks & access control
    function setClaimLock(bool lock) onlyOwner external {
        _setClaimLock(lock);
    }
    function setWithdrawLock(bool lock) onlyOwner external {
        _setWithdrawLock(lock);
    }
    function ownershipTransfer(address to) onlyOwner external {
        _ownershipTransfer(to);
    }

    /**
     * @notice Register a new future reward velocity point
     */
    function registerRewardVelocity(uint256 _blockNumber, uint256 _rewardPerBlock, uint256 _decrementUnitPerBlock) onlyOwner public {
        require(_blockNumber > block.number, "new Reward params should register earlier");
        require(registeredPoints.length == 0 || _blockNumber > registeredPoints[registeredPoints.length-1].blockNumber, "Earilier velocity points are already set.");
        _registerRewardVelocity(_blockNumber, _rewardPerBlock, _decrementUnitPerBlock);
    }
    function deleteRegisteredRewardVelocity(uint256 _index) onlyOwner external {
        require(_index >= passedPoint, "Reward velocity point already passed.");
        _deleteRegisteredRewardVelocity(_index);
    }

    /**
     * @notice Set the reward distribution parameters
     */
    function setRewardVelocity(uint256 _rewardPerBlock, uint256 _decrementUnitPerBlock) onlyOwner external {
        _updateRewardLane();
        _setParams(_rewardPerBlock, _decrementUnitPerBlock);
    }
}