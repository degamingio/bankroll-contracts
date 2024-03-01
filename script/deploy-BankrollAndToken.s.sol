// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";
import {MockToken} from "test/mock/MockToken.sol";

contract DeployBankroll is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

        address admin = vm.addr(adminPrivateKey);
        address manager = vm.addr(managerPrivateKey);
        uint256 maxRisk = 10_000;
        vm.startBroadcast(deployerPrivateKey);

        // deploy mock token
        MockToken token = new MockToken("Tether", "mUSDT");
        Bankroll bankroll = new Bankroll(admin, address(token), maxRisk);
        //bankroll.setManager(manager, true);

        vm.stopBroadcast();
    }
}
