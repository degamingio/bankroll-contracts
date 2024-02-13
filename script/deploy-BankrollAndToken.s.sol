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
        uint256 maxRisk = 10_000;
        vm.startBroadcast(deployerPrivateKey);

        address bankrollManager = 0x0000000000000000000000000000000000000000;

        // deploy mock token
        MockToken token = new MockToken("Tether", "mUSDT");
        Bankroll bankroll = new Bankroll(admin, address(token), bankrollManager, maxRisk);
        //bankroll.setManager(manager, true);

        vm.stopBroadcast();
    }
}
