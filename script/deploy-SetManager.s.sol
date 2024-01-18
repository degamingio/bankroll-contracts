// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";

contract SetManager is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Bankroll bankroll = Bankroll(
            0xaB4D4cbf4fd126A5A64d188D0429fCe7ffE7cf91
        );
        bankroll.setManager(0xdC73aE43D50764099db7Bad5EFE61039eA1C985e, true);
        vm.stopBroadcast();
    }
}
