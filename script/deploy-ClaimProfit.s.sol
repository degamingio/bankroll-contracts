// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";

contract ClaimProfit is Script {
    function run() public {
        uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

        Bankroll bankroll = Bankroll(
            0x1a3808184847DCCc2e8DE3Ae3024808F8a4f2896
        );
        // // Set manager
        vm.startBroadcast(managerPrivateKey);
        bankroll.claimProfit();
        vm.stopBroadcast();
    }
}
