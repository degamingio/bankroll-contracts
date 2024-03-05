// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DGBankrollManager} from "src/DGBankrollManager.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AddOperator is Script {
    uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");

    address token = vm.envAddress("TOKEN_ADDRESS");

    //                                                    |
    // PASTE IN ADDRESS HERE                              V
    DGBankrollManager bankrollManager = DGBankrollManager(0x6052DA350b789E8FEF2307Ea0Bc8464568325906);

    // PASTE IN        |
    // ADDRESS HERE    V
    address bankroll = 0xe0e943e7D5070840d6d0C026a69F07787c5132Cf;

    address tempOperator = address(0x0);

    function run() external {

        vm.startBroadcast(adminPrivateKey);

        bankrollManager.addOperator(tempOperator);
    }
}