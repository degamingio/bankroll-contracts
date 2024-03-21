// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Credit is Script {
    uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");

    address token = vm.envAddress("TOKEN_ADDRESS");

    uint256 operatorPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

    address operator = vm.addr(operatorPrivateKey);

    string public PATH_PREFIX = string.concat("deployment/", vm.toString(block.chainid));
    string public PROXY_ADMIN_PATH = string.concat(PATH_PREFIX, "/ProxyAdmin/address");
    string public BANKROLL_IMPL_PATH = string.concat(PATH_PREFIX, "/BankrollImpl/address");
    string public BANKROLL_MANAGER_PATH = string.concat(PATH_PREFIX, "/DGBankrollManager/address");
    string public FACTORY_PATH = string.concat(PATH_PREFIX, "/DGBankrollFactory/address");
    string public ESCROW_PATH = string.concat(PATH_PREFIX, "/DGEscrow/address");
    string public BANKROLL_PATH = string.concat(PATH_PREFIX, "/Bankroll/address");

    Bankroll bankroll = Bankroll(vm.parseAddress(vm.readFile(BANKROLL_PATH)));

    uint256 constant amount = 10_000e18;

    function run() external {
        vm.startBroadcast(adminPrivateKey);

        IERC20(token).approve(address(bankroll), amount);

        bankroll.credit(amount, operator);

        vm.stopBroadcast();
    }
}