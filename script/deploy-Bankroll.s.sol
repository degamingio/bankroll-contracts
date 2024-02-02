// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployBankroll is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");
        uint256 percentageRisk = 10_000;
        address token = vm.envAddress("TOKEN_ADDRESS");
        address admin = vm.envAddress("ADMIN_ADDRESS");
        address manager = vm.envAddress("MANAGER_ADDRESS");

        // Deploy contract
        vm.startBroadcast(deployerPrivateKey);
        Bankroll bankroll = new Bankroll(admin, token, percentageRisk);
        vm.stopBroadcast();

        // Set manager
        vm.startBroadcast(adminPrivateKey);
        bankroll.setManager(manager, true);
        vm.stopBroadcast();

        // Set bankroll max allowance
        vm.startBroadcast(managerPrivateKey);
        IERC20(token).approve(
            address(bankroll),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        ); //max int value
        vm.stopBroadcast();
    }
}
