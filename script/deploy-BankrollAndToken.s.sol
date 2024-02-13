// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";
import {MockToken} from "test/mock/MockToken.sol";

contract DeployBankroll is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        uint256 maxRisk = 10_000;
        vm.startBroadcast(deployerPrivateKey);

        // Replace address with bankroll manager
        address bankrollManager = 0x0000000000000000000000000000000000000000;

        // deploy mock token
        MockToken token = new MockToken("Tether", "mUSDT");
        new Bankroll(admin, address(token), bankrollManager, maxRisk);

        vm.stopBroadcast();
    }
}
