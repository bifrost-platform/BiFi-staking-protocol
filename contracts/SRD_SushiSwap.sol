// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

import "./DistributionModelV3.sol";

contract BFCETHSushiSwapReward is DistributionModelV3 {
    constructor(uint256 start, uint256 reward_per_block, uint256 dec_per_block)
        DistributionModelV3(
            msg.sender, //ower
            0x281Df7fc89294C84AfA2A21FfEE8f6807F9C9226, //swap_pool_token(BFCETH_Sushi)
            0x2791BfD60D232150Bff86b39B7146c0eaAA2BA81  //reward_token(bifi)
        ) public {
        _registerRewardVelocity(start, reward_per_block, dec_per_block);
    }
}

contract BiFiETHSushiSwapReward is DistributionModelV3 {
    constructor(uint256 start, uint256 reward_per_block, uint256 dec_per_block)
    DistributionModelV3(
        msg.sender, //owner
        0x0beC54c89a7d9F15C4e7fAA8d47ADEdF374462eD, //swap_pool_token(BiFiETH_Sushi)
        0x2791BfD60D232150Bff86b39B7146c0eaAA2BA81  //reward_token(bifi)
    ) public {
        _registerRewardVelocity(start, reward_per_block, dec_per_block);
    }
}