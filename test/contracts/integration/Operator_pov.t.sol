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
    address public badOperator = address(0x4);

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
        dgBankrollManager.addOperator(badOperator);

        dgBankrollManager.approveBankroll(bankrollAddress_0, 650);
        dgBankrollManager.approveBankroll(bankrollAddress_1, 650);
        dgBankrollManager.approveBankroll(bankrollAddress_2, 650);

        dgBankrollManager.setOperatorToBankroll(bankrollAddress_0, operator);
        dgBankrollManager.setOperatorToBankroll(bankrollAddress_1, operator);

        // Bankroll_2 is a shared bankroll
        dgBankrollManager.setOperatorToBankroll(bankrollAddress_2, operator);
        dgBankrollManager.setOperatorToBankroll(bankrollAddress_2, badOperator);

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

        assertEq(token.balanceOf(LP), 0);
        assertEq(token.balanceOf(address(bankroll_0)), 10_000e6);
        assertEq(token.balanceOf(address(bankroll_1)), 10_000e6);
        assertEq(token.balanceOf(address(bankroll_2)), 10_000e6);

        vm.warp(block.timestamp + 2 days);

        vm.prank(player_0);
        token.transfer(admin, 1_000e6);

        assertEq(token.balanceOf(admin), 1_000e6);
        vm.warp(block.timestamp + 2 hours);

        vm.prank(player_1);
        token.transfer(admin, 1_000e6);

        assertEq(token.balanceOf(admin), 2_000e6);
        vm.warp(block.timestamp + 20 minutes);

        vm.prank(player_2);
        token.transfer(admin, 1_000e6);

        assertEq(token.balanceOf(admin), 3_000e6);
        vm.warp(block.timestamp + 4 hours);

        vm.prank(player_3);
        token.transfer(admin, 1_000e6);

        assertEq(token.balanceOf(admin), 4_000e6);
        vm.warp(block.timestamp + 233 minutes);

        vm.prank(player_4);
        token.transfer(admin, 1_000e6);

        assertEq(token.balanceOf(admin), 5_000e6);
        vm.warp(block.timestamp + 3 hours);

        vm.startPrank(admin);

        token.approve(address(bankroll_0), 1_000_000_000e6);
        token.approve(address(bankroll_1), 1_000_000_000e6);
        token.approve(address(bankroll_2), 1_000_000_000e6);

        bankroll_0.creditAndDebit(1_000e6, 995e6, operator, player_0);

        assertEq(token.balanceOf(admin), 4_000e6);
        assertEq(token.balanceOf(player_0), 995e6);
        assertEq(token.balanceOf(address(bankroll_0)), 10_005e6);

        bankroll_1.creditAndDebit(1_000e6, 333e6, operator, player_1);

        assertEq(token.balanceOf(admin), 3_000e6);
        assertEq(token.balanceOf(player_1), 333e6);
        assertEq(token.balanceOf(address(bankroll_1)), 10_667e6);

        bankroll_2.creditAndDebit(500e6, 1_000e6, operator, player_2);

        assertEq(token.balanceOf(admin), 2_500e6);
        assertEq(token.balanceOf(player_2), 1_000e6);
        assertEq(token.balanceOf(address(bankroll_2)), 9_500e6);

        bankroll_1.creditAndDebit(500e6, 200e6, operator, player_2);

        assertEq(token.balanceOf(admin), 2_000e6);
        assertEq(token.balanceOf(player_2), 1_200e6);
        assertEq(token.balanceOf(address(bankroll_1)), 10_967e6);

        // on  behalf of player 3
        bankroll_0.credit(1_000e6, operator);

        assertEq(token.balanceOf(admin), 1_000e6);
        assertEq(token.balanceOf(player_3), 0);
        assertEq(token.balanceOf(address(bankroll_0)), 11_005e6);

        bankroll_2.creditAndDebit(1_000e6, 5e6, operator, player_4);

        assertEq(token.balanceOf(admin), 0);
        assertEq(token.balanceOf(player_4), 5e6);
        assertEq(token.balanceOf(address(bankroll_2)), 10_495e6);

        vm.stopPrank();

        vm.warp(block.timestamp + 123 minutes);

        // Play with bad operator as well
        vm.prank(player_2);
        token.transfer(admin, 1_200e6);

        vm.prank(admin);
        bankroll_2.creditAndDebit(1_200e6, 783, badOperator, player_2);

        vm.warp(block.timestamp + 2 days);

        // bad operator has done something bad and broken agreements
        vm.prank(admin);
        dgBankrollManager.blockOperator(badOperator);

        // Player 1 want to try to play with the bad operator
        // but this call should get reverted from here on

        vm.startPrank(player_1);
        token.transfer(admin, 100e6);

        vm.startPrank(admin);
        vm.expectRevert(DGErrors.NOT_AN_OPERATOR.selector);
        bankroll_2.creditAndDebit(100e6, 95e6, badOperator, player_1);

        // just to make sure other calls work
        bankroll_2.creditAndDebit(100e6, 95e6, operator, player_1);

        vm.warp(block.timestamp + 3 days);

        // Also make sure that claim profit works

        dgBankrollManager.claimProfit(address(bankroll_0));
        dgBankrollManager.claimProfit(address(bankroll_1));
        dgBankrollManager.claimProfit(address(bankroll_2));

        vm.stopPrank();

        assertEq(bankroll_0.getLpValue(LP) > 10_000e6, true);
        assertEq(bankroll_1.getLpValue(LP) > 10_000e6, true);
        assertEq(bankroll_2.getLpValue(LP) > 10_000e6, true);
    }
}