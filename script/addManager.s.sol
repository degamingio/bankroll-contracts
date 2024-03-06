// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";
//import {IBankroll} from "src/interfaces/IBankroll.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract DeployBankroll is Script {
    using SafeERC20 for IERC20; 
    function run() public {
        // Private keys
        //uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");
        //uint256 percentageRisk = 10_000;

        // Addresses
        address admin = vm.addr(adminPrivateKey);
        address manager = vm.addr(managerPrivateKey);
        address token = vm.envAddress("TOKEN_ADDRESS");

        //console.log("deployer: ", vm.addr(deployerPrivateKey));
        console.log("admin:    ", admin);
        console.log("manager:  ", manager);
        console.log("token:    ", token);

        // Instanciate contract
        Bankroll bankroll = Bankroll(
            0xBf4deaf7920E8BCb79Be176259e6A68cabe976B1
        );

        // Set manager
        vm.startBroadcast(adminPrivateKey);
        bankroll.setManager(manager, true);
        vm.stopBroadcast();

        // Set bankroll max allowance
        vm.startBroadcast(managerPrivateKey);
        // IERC20(token).approve(
            // address(bankroll),
            // 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        // ); //max int value
        IERC20(token).forceApprove(
            address(bankroll),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        vm.stopBroadcast();
    }
}
