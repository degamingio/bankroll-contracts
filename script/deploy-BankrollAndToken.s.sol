// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";
import {MockToken} from "test/mock/MockToken.sol";

contract DeployBankroll is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address manager = vm.envAddress("MANAGER_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        // deploy mock token
        MockToken token = new MockToken("Tether", "mUSDT");
        Bankroll bankroll = new Bankroll(admin, address(token));
        bankroll.setManager(manager, true);

        vm.stopBroadcast();
    }
}