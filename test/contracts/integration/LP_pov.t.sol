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


contract LPPov is Test {
    TransparentUpgradeableProxy public bankrollFactoryProxy;
    TransparentUpgradeableProxy public bankrollProxy;
    TransparentUpgradeableProxy public escrowProxy;
    TransparentUpgradeableProxy public bankrollManagerProxy;

    ProxyAdmin public proxyAdmin; 

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;

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
    address LP_0 = address(0x20);
    address LP_1 = address(0x21);
    address LP_2 = address(0x22);
    address LP_3 = address(0x23);
    address LP_4 = address(0x24);

    uint256 LPsUSDTAmount = 10_000e6;
    uint256 playerUSDTAmount = 100e6;

    uint256 maxRisk = 8_000;
    uint256 threshold = 1000e6;

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

        dgBankrollFactory.deployBankroll(address(token), maxRisk, threshold, "0x0");

        address bankrollAddress = dgBankrollFactory.bankrolls(dgBankrollFactory.bankrollCount() - 1);

        dgBankrollManager.addOperator(operator);

        dgBankrollManager.approveBankroll(bankrollAddress, 650);

        dgBankrollManager.setOperatorToBankroll(bankrollAddress, operator);

        bankroll = Bankroll(bankrollAddress);

        vm.stopPrank();

        vm.startPrank(admin);

        bankroll.maxContractsApprove();

        vm.stopPrank();

        token.mint(player_0, playerUSDTAmount);
        token.mint(player_1, playerUSDTAmount);
        token.mint(player_2, playerUSDTAmount);
        token.mint(player_3, playerUSDTAmount);
        token.mint(player_4, playerUSDTAmount);

        token.mint(LP_0, LPsUSDTAmount);
        token.mint(LP_1, LPsUSDTAmount);
        token.mint(LP_2, LPsUSDTAmount);
        token.mint(LP_3, LPsUSDTAmount);
        token.mint(LP_4, LPsUSDTAmount);

    }

    function test_LPPov() external{
        // Deposit liquidity from LP_0
        vm.startPrank(LP_0);

        token.approve(address(bankroll), LPsUSDTAmount);

        // FIRST COUNTDOWN (1 week) FOR MINIMUM DEPOSITION TIME
        // This will be reset 
        bankroll.depositFunds(8_000e6);
        vm.stopPrank();

        assertEq(token.balanceOf(address(bankroll)), 80_00e6);
        assertNotEq(bankroll.sharesOf(LP_0), 0);

        // LP_0 deposition time = 2 days
        vm.warp(block.timestamp + 2 days);

        // Play and win 20 USDT some from player_0

        vm.prank(player_0);
        token.transfer(admin, playerUSDTAmount);

        vm.startPrank(admin);
        token.approve(address(bankroll), 1_000_000_000e6);

        bankroll.creditAndDebit(playerUSDTAmount, 120e6, operator, player_0);

        vm.stopPrank();

        assertEq(token.balanceOf(player_0), 120e6);
        assertEq(token.balanceOf(address(bankroll)), 7_980e6);
        assertEq(bankroll.GGR(), 0-20e6);

        // LP_0 depoisition time = 2 days + 3 hours
        vm.warp(block.timestamp + 3 hours);

        // player_1 and player_2 both plays, player_2 wins 10 USDT, and player_1 loses everything

        vm.prank(player_1);
        token.transfer(admin, playerUSDTAmount);

        vm.prank(player_2);
        token.transfer(admin, playerUSDTAmount);

        assertEq(token.balanceOf(admin), playerUSDTAmount * 2);

        vm.startPrank(admin);
        bankroll.credit(playerUSDTAmount, operator);
        bankroll.creditAndDebit(playerUSDTAmount, 110e6, operator, player_2);
        vm.stopPrank();

        assertEq(token.balanceOf(admin), 0);
        assertEq(token.balanceOf(player_1), 0);
        assertEq(token.balanceOf(player_2), 110e6);
        assertEq(bankroll.GGR(), 70e6);
        assertEq(token.balanceOf(address(bankroll)), 8_070e6);

        // LP_0 deposition time = 2days + 33 hours = 3 days + 9 hours
        vm.warp(block.timestamp + 30 hours);

        // Deposit liquidity from LP_1
        // COUNTDOWN (1 weeks) minimumDepositionTime FOR LP_1 STARTS HERE
        vm.startPrank(LP_1);

        token.approve(address(bankroll), LPsUSDTAmount);

        bankroll.depositFunds(LPsUSDTAmount);
        vm.stopPrank();

        // LP_0 deposition time = 3days + 13 hours
        // LP_1 deposition time = 4 hours
        vm.warp(block.timestamp + 4 hours);

        // Deposit liquidity from LP_2
        // COUNTDOWN (1 weeks) minimumDepositionTime FOR LP_2 STARTS HERE
        vm.startPrank(LP_2);

        token.approve(address(bankroll), LPsUSDTAmount);

        bankroll.depositFunds(LPsUSDTAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(address(bankroll)), 28_070e6);

        // player_0 and player 3 plays, player_0 loses 115 USDT and player3 wins 100usdt
        vm.prank(player_0);
        token.transfer(admin, 120e6);

        vm.prank(player_3);
        token.transfer(admin, playerUSDTAmount);

        vm.startPrank(admin);
        bankroll.creditAndDebit(120e6, 5e6, operator, player_0);
        bankroll.creditAndDebit(playerUSDTAmount, 200e6, operator, player_3);
        vm.stopPrank();

        assertEq(token.balanceOf(address(bankroll)), 28_085e6);
        assertEq(token.balanceOf(admin), 0);
        assertEq(token.balanceOf(player_0), 5e6);
        assertEq(token.balanceOf(player_3), 200e6);
        assertEq(bankroll.GGR(), 85e6);

        // LP_0 deposition time = 4 days + 13 hours
        // LP_1 deposition time = 1 days + 4 hours
        // LP_2 deposition time = 1 days
        vm.warp(block.timestamp + 1 days);

        // LP_0 decides to put all of his USDT into the contract
        // LP_0 deposition time will be nulled from here
        vm.startPrank(LP_0);

        token.approve(address(bankroll), LPsUSDTAmount - 8_000e6);

        // LP_0 deposition time = 0
        // LP_1 deposition time = 1 days + 4 hours
        // LP_2 deposition time = 1 days
        bankroll.depositFunds(LPsUSDTAmount - 8_000e6);
        vm.stopPrank();

        // LP_0 deposition time = 0 + 40 hours = 1 days + 16 hours
        // LP_1 deposition time = 1 days + 44 hours = 2 days and 20 hour
        // LP_2 deposition time = 1 days + 40 hours = 2 days and 16 hours
        vm.warp(40 hours);

        // LP_3 eposits
        // COUNTDOWN (1 weeks) minimumDepositionTime FOR LP_3 STARTS HERE
        vm.startPrank(LP_3);

        token.approve(address(bankroll), LPsUSDTAmount);

        bankroll.depositFunds(LPsUSDTAmount);
        vm.stopPrank();

        assertEq(token.balanceOf(address(bankroll)), 40_085e6);

        // LP_0 deposition time = 3 days + 16 hours
        // LP_1 deposition time = 4 days and 20 hour
        // LP_2 deposition time = 4 days and 16 hours
        // LP_3 deporition time = 2 days
        vm.warp(block.timestamp + 2 days);

        // player_3 loses 150 and player_4 loses 20
        vm.prank(player_3);
        token.transfer(admin, 180e6);

        vm.prank(player_4);
        token.transfer(admin, playerUSDTAmount);

        // LP 4 deposits
        // COUNTDOWN (1 weeks) minimumDepositionTime FOR LP_4 STARTS HERE
        vm.startPrank(LP_4);

        token.approve(address(bankroll), LPsUSDTAmount);

        bankroll.depositFunds(LPsUSDTAmount);
        vm.stopPrank();

        vm.startPrank(admin);
        bankroll.creditAndDebit(180e6, 30e6, operator, player_3);
        bankroll.creditAndDebit(playerUSDTAmount, 80e6, operator, player_4);
        vm.stopPrank();

        assertEq(token.balanceOf(admin), 0);
        assertEq(token.balanceOf(player_3), 50e6);
        assertEq(token.balanceOf(player_4), 80e6);
        assertEq(token.balanceOf(address(bankroll)), 50_255e6);
        assertEq(bankroll.GGR(), 255e6);

        // LP_0 deposition time = 5 days + 18 hours
        // LP_1 deposition time = 6 days and 22 hour
        // LP_2 deposition time = 6 days and 18 hours
        // LP_3 deposition time = 4 days and 2 hours
        // LP_4 deposition time = 2 days and 2 hours
        vm.warp(block.timestamp + 50 hours);

        // Degaming calls the claim profit function

        vm.startPrank(admin);
        dgBankrollManager.claimProfit(address(bankroll));

        console.log(bankroll.getLpValue(LP_0));
        console.log(bankroll.getLpValue(LP_4));
    }
}