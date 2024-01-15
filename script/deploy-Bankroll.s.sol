// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";

contract DeployBankroll is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address mUSD = vm.envAddress("MUSD_ADDRESS");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address manager = vm.envAddress("MANAGER_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        Bankroll bankroll = new Bankroll(admin, mUSD);
        bankroll.setManager(manager, true);

        vm.stopBroadcast();
    }
}
