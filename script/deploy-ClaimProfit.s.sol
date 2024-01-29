// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";

contract ClaimProfit is Script {
    function run() public {
        uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

        Bankroll bankroll = Bankroll(
            0x8C26aACD57d3B4C19B9AC8aD224083dcCfb6A057
        );
        // // Set manager
        vm.startBroadcast(managerPrivateKey);
        bankroll.claimProfit();
        vm.stopBroadcast();
    }
}
