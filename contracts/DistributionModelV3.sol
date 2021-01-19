// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import "./module/externalModule.sol";

/**
 * @title BiFi's Reward Distribution Contract
 * @notice Implements voting process along with vote delegation
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract DistributionModelV3 is externalModule {
    constructor(address _owner, address _lpErc, address _rewardErc) public {
        owner = _owner;
        lpErc = ERC20(_lpErc);
        rewardErc = ERC20(_rewardErc);
        lastBlockNum = block.number;
    }
}

contract BFCModel is DistributionModelV3 {
    constructor(address _owner, address _lpErc, address _rewardErc, uint256 _start)
    DistributionModelV3(_owner, _lpErc, _rewardErc) public {
        _registerRewardVelocity(_start, 0x3935413a1cdd90ff, 0x62e9bea75f);
    }
}

contract BFCETHModel is DistributionModelV3 {
    constructor(address _owner, address _lpErc, address _rewardErc, uint256 _start)
    DistributionModelV3(_owner, _lpErc, _rewardErc) public {
        _registerRewardVelocity(_start, 0xe4d505786b744b3f, 0x18ba6fb966b);
    }
}

contract BiFiETHModel is DistributionModelV3 {
    constructor(address _owner, address _lpErc, address _rewardErc, uint256 _start)
    DistributionModelV3(_owner, _lpErc, _rewardErc) public {
        _registerRewardVelocity(_start, 0x11e0a46e285a68955, 0x1ee90ba90c4);
    }
}