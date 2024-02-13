// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

/* DeGaming Contracts */
import {Bankroll} from "src/Bankroll.sol";

/* OpenZeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployBankroll is Script {
    function run() public {
        // Private keys
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");
        uint256 percentageRisk = 10_000;

        // Addresses
        address admin = vm.addr(adminPrivateKey);
        address operator = vm.addr(managerPrivateKey);
        address token = vm.envAddress("TOKEN_ADDRESS");
        address bankrollManager = 0x0000000000000000000000000000000000000000;

        console.log("deployer: ", vm.addr(deployerPrivateKey));
        console.log("admin:    ", admin);
        console.log("operator:  ", operator);
        console.log("token:    ", token);

        // Deploy contract
        vm.startBroadcast(deployerPrivateKey);
        Bankroll bankroll = new Bankroll(admin, token, bankrollManager, percentageRisk);
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
