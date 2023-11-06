// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

contract Experiment {
    bool lol;
    uint128 a;
    uint128 b;

    function setAB(uint128 newA, uint128 newB) external returns (bool) {
        a = newA;
        b = newB;

        return true;
    }

    function setLol(bool newLol) external {
        lol = newLol;
    }
}
