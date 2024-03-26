// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import "../../lib/properties/contracts/util/Hevm.sol";
import {Setup} from "./Setup.sol";

abstract contract TargetFunctions is Setup, Properties, BeforeAfter {
    function testDepositFunds(uint256 amount) public {}

    function testWithdraw(uint256 shares) public {}
}
