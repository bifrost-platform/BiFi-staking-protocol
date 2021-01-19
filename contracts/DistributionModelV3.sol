//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.12;

import "./module/externalModule.sol";

/**
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract DistributionModelV3 is externalModule {
    constructor(address _lpErc, address _rewardErc, uint256 _initialRewardPerBlock, uint256 _decrement) public {
        owner = msg.sender;
        lpErc = ERC20(_lpErc);
        rewardErc = ERC20(_rewardErc);

        rewardPerBlock = _initialRewardPerBlock;
        decrementUnitPerBlock = _decrement;
        lastBlockNum = block.number;
    }
}

contract LPModel is DistributionModelV3 {
    constructor(address _lpErc, address _rewardErc, uint256 _initialRewardPerBlock, uint256 _decrement)
    DistributionModelV3(_lpErc, _rewardErc, _initialRewardPerBlock, _decrement) public {}
}

contract StakeModel is DistributionModelV3 {
    constructor(address _lpErc, address _rewardErc, uint256 _initialRewardPerBlock, uint256 _decrement)
    DistributionModelV3(_lpErc, _rewardErc, _initialRewardPerBlock, _decrement) public {}
}