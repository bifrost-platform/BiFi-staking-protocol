// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title BiFi's safe-math Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract safeMathModule {
    uint256 constant one = 1 ether;

    function expDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeDiv( safeMul(a, one), b);
    }
    function expMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return safeDiv( safeMul(a, b), one);
    }
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addtion overflow");
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "SafeMath: subtraction overflow");
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if(a == 0) { return 0;}
        uint256 c = a * b;
        require( (c/a) == b, "SafeMath: multiplication overflow");
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return (a/b);
    }
}
