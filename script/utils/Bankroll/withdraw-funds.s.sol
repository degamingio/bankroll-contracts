// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import {Script} from "forge-std/Script.sol";
// import {Bankroll} from "src/Bankroll.sol";

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract WithdrawFunds is Script {
    // uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");

    // address token = vm.envAddress("TOKEN_ADDRESS");

    // uint256 operatorPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

    // address operator = vm.addr(operatorPrivateKey);

    // //                           |
    // // PASTE IN ADDRESS HERE     V
    // Bankroll bankroll = Bankroll(0xf48e37FC7a7767d04e39dE8effDD5b47A790e20D);

    // uint256 constant amount = 100;

    // function run() external {

        // vm.startBroadcast(adminPrivateKey);

        // bankroll.withdrawAll();
    // }
// }