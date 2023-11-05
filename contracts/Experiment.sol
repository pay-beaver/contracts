// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

contract Experiment {
    uint256 a;
    uint256 b;

    function setAB(uint256 newA, uint256 newB) external returns (bool) {
        a = newA;
        b = newB;

        return true;
    }
}
