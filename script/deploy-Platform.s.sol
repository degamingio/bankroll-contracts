// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
import {DGEscrow} from "src/DGEscrow.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";

contract DeployPlatform is Script {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

    // TransparentUpgradeableProxy public bankrollProxy;
    TransparentUpgradeableProxy public bankrollFactoryProxy;
    TransparentUpgradeableProxy public bankrollProxy;

    ProxyAdmin public proxyAdmin; 

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;

    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
    uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

    address deployerPubKey = vm.addr(deployerPrivateKey);

    address deGaming = 0x1d424382e8e09CC6F8425c9F32D2c695E7698db7;

    // Addresses
    address public admin = vm.addr(adminPrivateKey);
    address public deployer = vm.addr(deployerPrivateKey);
    address public operator = vm.addr(managerPrivateKey);
    address public token = vm.envAddress("TOKEN_ADDRESS");

    string public PATH_PREFIX = string.concat("deployment/", vm.toString(block.chainid));
    string public PROXY_ADMIN_PATH = string.concat(PATH_PREFIX, "/ProxyAdmin/address");
    string public BANKROLL_IMPL_PATH = string.concat(PATH_PREFIX, "/BankrollImpl/address");
    string public BANKROLL_MANAGER_PATH = string.concat(PATH_PREFIX, "/DGBankrollManager/address");
    string public FACTORY_PATH = string.concat(PATH_PREFIX, "/DGBankrollFactory/address");
    string public ESCROW_PATH = string.concat(PATH_PREFIX, "/DGEscrow/address");
    string public BANKROLL_PATH = string.concat(PATH_PREFIX, "/Bankroll/address");

    uint256 maxRisk = 10_000;
    uint256 threshold = 10_000;

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        console.log("#######################################################");
        console.log("ADDRESSES:");
        console.log("deployer: ", vm.addr(deployerPrivateKey));
        console.log("admin:    ", admin);
        console.log("Operator: ", vm.addr(managerPrivateKey));
        console.log("token:    ", token);
        console.log("#######################################################");
        console.log("PATHS:");
        console.log(PROXY_ADMIN_PATH);
        console.log(BANKROLL_IMPL_PATH);
        console.log(BANKROLL_MANAGER_PATH);
        console.log(FACTORY_PATH);
        console.log(ESCROW_PATH);
        console.log(BANKROLL_PATH);
        console.log("#######################################################");

        dgBankrollManager = new DGBankrollManager(admin);

        vm.writeFile(BANKROLL_MANAGER_PATH, vm.toString(address(dgBankrollManager)));

        dgEscrow = new DGEscrow(1 weeks, address(dgBankrollManager));

        vm.writeFile(ESCROW_PATH, vm.toString(address(dgEscrow)));

        proxyAdmin = new ProxyAdmin();

        vm.writeFile(PROXY_ADMIN_PATH, vm.toString(address(proxyAdmin)));

        //bankroll = new Bankroll();

        bankrollProxy = new TransparentUpgradeableProxy(
            address(new Bankroll()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Bankroll.initialize.selector,
                admin,
                address(token),
                address(dgBankrollManager),
                address(dgEscrow),
                deployer,
                maxRisk,
                threshold
            )
        );

        vm.writeFile(BANKROLL_IMPL_PATH, vm.toString(address(bankrollProxy)));

        bankrollFactoryProxy = new TransparentUpgradeableProxy(
            address(new DGBankrollFactory()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGBankrollFactory.initialize.selector,
                address(bankrollProxy),
                address(dgBankrollManager),
                address(dgEscrow),
                deGaming,
                admin
            )
        );

        vm.writeFile(FACTORY_PATH, vm.toString(address(bankrollFactoryProxy)));

        dgBankrollFactory = DGBankrollFactory(address(bankrollFactoryProxy));

        dgBankrollManager.grantRole(keccak256("ADMIN"), address(dgBankrollFactory));

        dgBankrollManager.grantRole(keccak256("ADMIN"), deployer);
        // if (createCasino) {
            // dgBankrollFactory.deployBankroll(token, maxRisk, threshold, "0x0");
            // address bankrollAddress = dgBankrollFactory.bankrolls(0);
            // dgBankrollManager.addOperator(operator);
            // dgBankrollManager.approveBankroll(address(bankrollAddress), 0);
            // dgBankrollManager.setOperatorToBankroll(address(bankrollAddress), operator);
            // vm.writeFile(BANKROLL_PATH, vm.toString(address(bankrollAddress)));
        // }

        vm.stopBroadcast();
    }
}