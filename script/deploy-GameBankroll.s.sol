// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {GameBankroll} from "src/GameBankroll.sol";

contract DeployGameBankroll is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address mUSD = vm.envAddress("MUSD_ADDRESS");
        address manager = vm.envAddress("MANAGER_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        new GameBankroll(manager, mUSD);

        vm.stopBroadcast();
    }
}
