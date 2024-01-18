// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";

contract DeployGameBankroll is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address mUSD = vm.envAddress("MUSD_ADDRESS");
        address manager = vm.envAddress("ADMIN_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        new Bankroll(manager, mUSD);

        vm.stopBroadcast();
    }
}
