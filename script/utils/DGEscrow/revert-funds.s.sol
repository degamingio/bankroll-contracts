// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
//import {DGBankrollManager} from "src/DGBankrollManager.sol";
import {DGEscrow} from "src/DGEscrow.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClaimProfit is Script {
    // uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");

    // address token = vm.envAddress("TOKEN_ADDRESS");

    // string public PATH_PREFIX = string.concat("deployment/", vm.toString(block.chainid));
    // string public PROXY_ADMIN_PATH = string.concat(PATH_PREFIX, "/ProxyAdmin/address");
    // string public BANKROLL_IMPL_PATH = string.concat(PATH_PREFIX, "/BankrollImpl/address");
    // string public BANKROLL_MANAGER_PATH = string.concat(PATH_PREFIX, "/DGBankrollManager/address");
    // string public FACTORY_PATH = string.concat(PATH_PREFIX, "/DGBankrollFactory/address");
    // string public ESCROW_PATH = string.concat(PATH_PREFIX, "/DGEscrow/address");
    // string public BANKROLL_PATH = string.concat(PATH_PREFIX, "/Bankroll/address");
    // string public ID_PATH = string.concat(PATH_PREFIX, "/EscrowId/bytes");

    // DGEscrow escrow = DGEscrow(vm.parseAddress(vm.readFile(ESCROW_PATH)));

    // function run() public {
        // vm.startBroadcast(adminPrivateKey);

        // DGDataTypes.EscrowEntry memory entry = DGDataTypes.EscrowEntry(
            // 0x242f2d72f6B9F534B6182d911e719b7be7a81861,
            // 0x312BA46064e1fe5904362BfB0C52c38F20d3Ef44,
            // 0xDef28f7d7F3700e30F403B6350Fb54a358469874,
            // 0xc6ADeA8722C2DB1EFF810f429C3C09BA00E1F25C,
            // 1711104158
        // );

        // bytes memory id = abi.encode(entry);

        // // PASTE ID HERE
        // escrow.revertFunds(id);

        // vm.stopBroadcast();
    // }
}