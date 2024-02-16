// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {MockToken} from "test/mock/MockToken.sol";

contract Credit is Script {
    uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");

    address token = vm.envAddress("TOKEN_ADDRESS");

    uint256 constant amount = 100;

    MockToken USDT = MockToken(token);

    function run() external {

        vm.startBroadcast(adminPrivateKey);

        USDT.mint(vm.addr(adminPrivateKey), 1_000_000_000_000_000_000_000_000);

    }
}