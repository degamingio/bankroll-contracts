// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";
import {TargetFunctions} from "./TargetFunctions.sol";

contract EchidnaTester is Setup, TargetFunctions {
    constructor() {
        setup();
    }
}
