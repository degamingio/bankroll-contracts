// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";

/* OpenZeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* OpenZeppelin Contract */
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


/* DeGaming Contracts */
import {Bankroll} from "src/Bankroll.sol";
import {DGBankrollManager} from "src/DGBankrollManager.sol";
import {DGBankrollFactory} from "src/DGBankrollFactory.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";

contract DeployPlatform is Script {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

    // TransparentUpgradeableProxy public bankrollProxy;
    TransparentUpgradeableProxy public bankrollFactoryProxy;

    ProxyAdmin public proxyAdmin; 

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    Bankroll public bankroll;

    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
    uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

    address deployerPubKey = vm.addr(deployerPrivateKey);

    address deGaming = 0x1d424382e8e09CC6F8425c9F32D2c695E7698db7;

    // Addresses
    address admin = vm.addr(adminPrivateKey);
    address token = vm.envAddress("TOKEN_ADDRESS");

    function run() public {

        vm.startBroadcast(deployerPrivateKey);

        console.log("deployer: ", vm.addr(deployerPrivateKey));
        console.log("admin:    ", admin);
        console.log("token:    ", token);

        dgBankrollManager = new DGBankrollManager(admin);

        proxyAdmin = new ProxyAdmin(msg.sender);

        // bankrollProxy = new TransparentUpgradeableProxy(
            // address(new Bankroll()),
            // address(proxyAdmin),
            // abi.encodeWithSelector(
                // Bankroll.initialize.selector,
                // admin,
                // address(token),
                // address(dgBankrollManager),
                // msg.sender,
                // maxRisk
            // )
        // );
        
        // Bankroll implementation contract
        //bankroll = Bankroll(address(bankrollProxy));
        bankroll = new Bankroll();        


        bankrollFactoryProxy = new TransparentUpgradeableProxy(
            address(new DGBankrollFactory()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGBankrollFactory.initialize.selector,
                address(bankroll),
                address(dgBankrollManager),
                deGaming,
                admin
            )
        );

        dgBankrollFactory = DGBankrollFactory(address(bankrollFactoryProxy));

        dgBankrollManager.setFactory(address(dgBankrollFactory));

        vm.stopBroadcast();
    }
}