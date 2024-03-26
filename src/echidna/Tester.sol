// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Setup} from "./Setup.sol";
import {TargetFunctions} from "./TargetFunctions.sol";

contract Tester is Setup, TargetFunctions {
    constructor() {
        setup();
    }
}
