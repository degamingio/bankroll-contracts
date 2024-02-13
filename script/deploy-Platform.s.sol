// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "forge-std/Script.sol";

/* OpenZeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* DeGaming Contracts */
import {Bankroll} from "src/Bankroll.sol";
import {DGBankrollManager} from "src/DGBankrollManager.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";

contract DGBankrollManagerTest is Script {
    DGBankrollManager public dgBankrollManager;
    Bankroll public bankroll;

    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
    uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

    address deGaming = 0x1d424382e8e09CC6F8425c9F32D2c695E7698db7;

    // Addresses
    address admin = vm.addr(adminPrivateKey);
    address token = vm.envAddress("TOKEN_ADDRESS");

    // replace with actual address
    address operator = vm.addr(managerPrivateKey);

    uint256 maxRisk = 10_000;

    function setUp() public {
        deGaming = address(0x2);

        dgBankrollManager = new DGBankrollManager(deGaming);

        bankroll = new Bankroll(admin, address(token), address(dgBankrollManager), maxRisk);

        dgBankrollManager.approveBankroll(address(bankroll));

        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);

        vm.prank(admin);
    
        IERC20(token).approve(
            address(bankroll),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }
}