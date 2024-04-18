// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

/* OpenZeppelin contract */
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/* DeGaming Contracts */
import {Bankroll} from "src/Bankroll.sol";
import {DGBankrollManager} from "src/DGBankrollManager.sol";
import {DGBankrollFactory} from "src/DGBankrollFactory.sol";
import {DGEscrow} from "src/DGEscrow.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/* Mock Contracts */
import {MockToken} from "test/mock/MockToken.sol";


contract OperatorPov is Test {
    TransparentUpgradeableProxy public bankrollFactoryProxy;
    TransparentUpgradeableProxy public bankrollProxy;
    TransparentUpgradeableProxy public escrowProxy;
    TransparentUpgradeableProxy public bankrollManagerProxy;

    ProxyAdmin public proxyAdmin; 

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;
    Bankroll public bankroll_0;
    Bankroll public bankroll_1;
    Bankroll public bankroll_2;

    address deGaming = address(0x0);

    // Addresses
    address public admin = address(0x1);
    address public deployer = address(0x2);
    address public operator = address(0x3);

    // player addresses:
    address player_0 = address(0x10);
    address player_1 = address(0x11);
    address player_2 = address(0x12);
    address player_3 = address(0x13);
    address player_4 = address(0x14);

    // LP addresses
    address LP = address(0x20);

    uint256 LPsUSDTAmount = 30_000e6;
    uint256 playerUSDTAmount = 1_000e6;

    uint256 maxRisk = 8_000;
    uint256 threshold = 1_000e6;

    MockToken token = new MockToken("Tether", "USDT");

    function setUp() public {
        vm.startPrank(deployer);

        proxyAdmin = new ProxyAdmin();

        bankrollManagerProxy = new TransparentUpgradeableProxy(
            address(new DGBankrollManager()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGBankrollManager.initialize.selector,
                admin
            )
        );

        dgBankrollManager = DGBankrollManager(address(bankrollManagerProxy));

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

        bankroll = new Bankroll();

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

        dgBankrollFactory = DGBankrollFactory(address(bankrollFactoryProxy));

        dgBankrollManager.grantRole(keccak256("ADMIN"), address(dgBankrollFactory));

        dgBankrollManager.grantRole(keccak256("ADMIN"), deployer);

        dgBankrollManager.grantRole(keccak256("ADMIN"), admin);

        dgEscrow.grantRole(keccak256("ADMIN"), admin);

        // Deploy bankroll 0 for the operator
        dgBankrollFactory.deployBankroll(address(token), maxRisk, threshold, "0x0");
        address bankrollAddress_0 = dgBankrollFactory.bankrolls(dgBankrollFactory.bankrollCount() - 1);

        // Deploy bankroll 1 for the operator
        dgBankrollFactory.deployBankroll(address(token), maxRisk, threshold, "0x1");
        address bankrollAddress_1 = dgBankrollFactory.bankrolls(dgBankrollFactory.bankrollCount() - 1);

        // Deploy bankroll 2 for the operator
        dgBankrollFactory.deployBankroll(address(token), maxRisk, threshold, "0x2");
        address bankrollAddress_2 = dgBankrollFactory.bankrolls(dgBankrollFactory.bankrollCount() - 1);

        dgBankrollManager.addOperator(operator);

        dgBankrollManager.approveBankroll(bankrollAddress_0, 650);
        dgBankrollManager.approveBankroll(bankrollAddress_1, 650);
        dgBankrollManager.approveBankroll(bankrollAddress_2, 650);

        dgBankrollManager.setOperatorToBankroll(bankrollAddress_0, operator);
        dgBankrollManager.setOperatorToBankroll(bankrollAddress_1, operator);
        dgBankrollManager.setOperatorToBankroll(bankrollAddress_2, operator);

        bankroll_0 = Bankroll(bankrollAddress_0);
        bankroll_1 = Bankroll(bankrollAddress_1);
        bankroll_2 = Bankroll(bankrollAddress_2);

        vm.stopPrank();

        vm.startPrank(admin);

        bankroll_0.maxContractsApprove();
        bankroll_1.maxContractsApprove();
        bankroll_2.maxContractsApprove();

        vm.stopPrank();

        token.mint(player_0, playerUSDTAmount);
        token.mint(player_1, playerUSDTAmount);
        token.mint(player_2, playerUSDTAmount);
        token.mint(player_3, playerUSDTAmount);
        token.mint(player_4, playerUSDTAmount);

        token.mint(LP, LPsUSDTAmount);
    }

    function test_operatorPov() external {
        vm.startPrank(LP);
        token.approve(address(bankroll_0), 10_000e6);
        token.approve(address(bankroll_1), 10_000e6);
        token.approve(address(bankroll_2), 10_000e6);

        bankroll_0.depositFunds(10_000e6);
        bankroll_1.depositFunds(10_000e6);
        bankroll_2.depositFunds(10_000e6);

        vm.stopPrank();
    }
}