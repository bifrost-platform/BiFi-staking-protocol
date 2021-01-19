//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./viewModule.sol";

/**
 * @title Liquidity staking service contracts (external)
 * @notice Implement the service actions.
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
     * @notice Deposit the Contribution Tokens
     * @param amount The amount of the Contribution Tokens
     */
    function deposit(uint256 amount) external {
        address userAddr = msg.sender;
        _redeemAll(userAddr);
        _deposit(userAddr, amount);
    }

    /**
     * @notice Deposit the Contribution Tokens by another
     * @param amount The amount of the Contribution Tokens
     * @param userAddr The Address of Deposit Target
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
     * @notice Claim the Reward Tokens by another
     * @param userAddr The Address of Claim Target
     * @dev Transfer all reward the user has earned at once.
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
    function registerRewardVelocity(uint256 _blockNumber, uint256 _rewardPerBlock, uint256 _decrementUnitPerBlock) onlyOwner external {
        require(_blockNumber > block.number, "new Reward params should register earlier");
        require(registeredPoints.length == 0 || _blockNumber > registeredPoints[registeredPoints.length-1].blockNumber, "Earilier velocity points are already set.");
        _registerRewardVelocity(_blockNumber, _rewardPerBlock, _decrementUnitPerBlock);
    }
    function deleteRegisteredRewardVelocity(uint256 _index) onlyOwner external {
        require(_index >= passedPoint, "Reward velocity point already apssed.");
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