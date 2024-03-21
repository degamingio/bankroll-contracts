// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

import {MockToken} from "test/mock/MockToken.sol";

contract MintTokens is Script {
    uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");

    address token = vm.envAddress("TOKEN_ADDRESS");

    uint256 constant amount = 100;

    MockToken USDT = MockToken(token);

    string public PATH_PREFIX = string.concat("deployment/", vm.toString(block.chainid));
    string public PROXY_ADMIN_PATH = string.concat(PATH_PREFIX, "/ProxyAdmin/address");
    string public BANKROLL_IMPL_PATH = string.concat(PATH_PREFIX, "/BankrollImpl/address");
    string public BANKROLL_MANAGER_PATH = string.concat(PATH_PREFIX, "/DGBankrollManager/address");
    string public FACTORY_PATH = string.concat(PATH_PREFIX, "/DGBankrollFactory/address");
    string public ESCROW_PATH = string.concat(PATH_PREFIX, "/DGEscrow/address");
    string public BANKROLL_PATH = string.concat(PATH_PREFIX, "/Bankroll/address");

    address bankroll = vm.parseAddress(vm.readFile(BANKROLL_PATH));

    function run() public {

        vm.startBroadcast(adminPrivateKey);

        USDT.mint(vm.addr(adminPrivateKey), 1_000_000_000_000_000_000_000_000);

        USDT.approve(bankroll, 1_000_000_000_000_000_000_000_000);
    }
}