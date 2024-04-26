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

contract CreateBankroll is Script {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

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

    address deGaming = 0x021F02BfD602F3f7b0c250FF8d707121a81Bd282;

    // Addresses
    // address public admin = vm.addr(adminPrivateKey);
    address public admin = 0x2a60D6b74E4097114C2450aeCDeB450B2943B3e6;
    address public deployer = vm.addr(deployerPrivateKey);
    //address public operator = vm.addr(managerPrivateKey);
    address public operator = 0x3440E7FC8c60418963373F3664830Ed6791BD4C0;
    address public token = vm.envAddress("TOKEN_ADDRESS");

    string public PATH_PREFIX = string.concat("deployment/", vm.toString(block.chainid));
    string public PROXY_ADMIN_PATH = string.concat(PATH_PREFIX, "/ProxyAdmin/address");
    string public BANKROLL_IMPL_PATH = string.concat(PATH_PREFIX, "/BankrollImpl/address");
    string public BANKROLL_MANAGER_PATH = string.concat(PATH_PREFIX, "/DGBankrollManager/address");
    string public FACTORY_PATH = string.concat(PATH_PREFIX, "/DGBankrollFactory/address");
    string public ESCROW_PATH = string.concat(PATH_PREFIX, "/DGEscrow/address");
    string public BANKROLL_PATH = string.concat(PATH_PREFIX, "/Bankroll/address");

    uint256 maxRisk = 8_000;
    uint256 threshold = 1_000e6;

    address public deployWallet = 0x3745f639898b064B0278574267Be7D7acDcd6C44;

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        proxyAdmin = ProxyAdmin(vm.parseAddress(vm.readFile(PROXY_ADMIN_PATH)));
        bankrollProxy = TransparentUpgradeableProxy(vm.parseAddress(vm.readFile(BANKROLL_IMPL_PATH)));
        dgBankrollManager = DGBankrollManager(vm.parseAddress(vm.readFile(BANKROLL_MANAGER_PATH)));
        dgBankrollFactory = DGBankrollFactory(vm.parseAddress(vm.readFile(FACTORY_PATH)));
        dgEscrow = DGEscrow(vm.parseAddress(vm.readFile(ESCROW_PATH)));
        bankroll = Bankroll(vm.parseAddress(vm.readFile(BANKROLL_PATH)));

        bankroll.grantRole(keccak256("DEFAULT_ADMIN_ROLE"), deployWallet);
        dgBankrollFactory.grantRole(keccak256("DEFAULT_ADMIN_ROLE"), deployWallet);
        dgBankrollManager.grantRole(keccak256("DEFAULT_ADMIN_ROLE"), deployWallet);
        dgEscrow.grantRole(keccak256("DEFAULT_ADMIN_ROLE"), deployWallet);
        dgBankrollManager.grantRole(keccak256("ADMIN"), deployWallet);
        dgEscrow.grantRole(keccak256("ADMIN"), deployWallet);
        vm.stopBroadcast();
    }
}