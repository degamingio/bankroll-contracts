// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract Credit is Script {
    uint256 adminPrivateKeys = vm.envUint("ADMIN_PRIVATE_KEY");

    uint256 playerPrivateKeys = vm.envUint("");
}