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

    TransparentUpgradeableProxy public bankrollFactoryProxy;
    TransparentUpgradeableProxy public bankrollProxy;
    TransparentUpgradeableProxy public escrowProxy;
    TransparentUpgradeableProxy public bankrollManagerProxy;

    ProxyAdmin public proxyAdmin; 

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;

    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
    uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

    address deployerPubKey = vm.addr(deployerPrivateKey);

    address deGaming = 0x021F02BfD602F3f7b0c250FF8d707121a81Bd282;

    // Addresses
    // address public admin = vm.addr(adminPrivateKey);
    address public admin = 0x2a60D6b74E4097114C2450aeCDeB450B2943B3e6;
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
        console.log("deployer:    ", vm.addr(deployerPrivateKey));
        console.log("Eth balance: ", vm.addr(deployerPrivateKey).balance);
        console.log("admin:       ", admin);
        console.log("Eth balance: ", admin.balance);
        console.log("Operator:    ", vm.addr(managerPrivateKey));
        console.log("Eth balance: ", vm.addr(managerPrivateKey).balance);
        console.log("token:       ", token);
        console.log("#######################################################");
        console.log("PATHS:");
        console.log(PROXY_ADMIN_PATH);
        console.log(BANKROLL_IMPL_PATH);
        console.log(BANKROLL_MANAGER_PATH);
        console.log(FACTORY_PATH);
        console.log(ESCROW_PATH);
        console.log(BANKROLL_PATH);
        console.log("#######################################################");

        proxyAdmin = new ProxyAdmin();

        bankrollManagerProxy = new TransparentUpgradeableProxy(
            address(new DGBankrollManager()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGBankrollManager.initialize.selector,
                deGaming
            )
        );

        dgBankrollManager = DGBankrollManager(address(bankrollManagerProxy));

        vm.writeFile(BANKROLL_MANAGER_PATH, vm.toString(address(dgBankrollManager)));

        // dgEscrow = new DGEscrow(1 weeks, address(dgBankrollManager));

        escrowProxy = new TransparentUpgradeableProxy(
            address(new DGEscrow()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGEscrow.initialize.selector,
                1 weeks,
                address(dgBankrollManager)
            )
        );

        dgEscrow = DGEscrow(address(escrowProxy));

        vm.writeFile(ESCROW_PATH, vm.toString(address(dgEscrow)));

        vm.writeFile(PROXY_ADMIN_PATH, vm.toString(address(proxyAdmin)));

        bankroll = new Bankroll();

        vm.writeFile(BANKROLL_IMPL_PATH, vm.toString(address(bankroll)));

        bankrollFactoryProxy = new TransparentUpgradeableProxy(
            address(new DGBankrollFactory()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGBankrollFactory.initialize.selector,
                address(bankroll),
                address(dgBankrollManager),
                address(dgEscrow),
                admin,
                deGaming
            )
        );

        vm.writeFile(FACTORY_PATH, vm.toString(address(bankrollFactoryProxy)));

        dgBankrollFactory = DGBankrollFactory(address(bankrollFactoryProxy));

        dgBankrollManager.grantRole(keccak256("ADMIN"), address(dgBankrollFactory));

        dgBankrollManager.grantRole(keccak256("ADMIN"), deployer);
        
        dgBankrollManager.grantRole(keccak256("ADMIN"), admin);
        
        dgEscrow.grantRole(keccak256("ADMIN"), admin);

        vm.stopBroadcast();
    }
}