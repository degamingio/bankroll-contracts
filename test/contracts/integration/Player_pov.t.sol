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


contract PlayerPov is Test {
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
    address LP = address(0x20);

    uint256 LPsUSDTAmount = 10_000e6;
    uint256 playerUSDTAmount = 5_000e6;

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

        token.mint(LP, LPsUSDTAmount);
    }

    function test_PlayerPov() external {
        vm.startPrank(LP);
        token.approve(address(bankroll), 10_000e6);
        bankroll.depositFunds(10_000e6);
        vm.stopPrank();

        vm.warp(block.timestamp + 83 hours);

        assertEq(token.balanceOf(LP), 0);
        assertEq(token.balanceOf(address(bankroll)), 10_000e6);

        vm.warp(block.timestamp + 3 days);

        vm.prank(player_0);
        token.transfer(admin, 2_000e6);

        assertEq(token.balanceOf(admin), 2_000e6);
        vm.warp(block.timestamp + 2 hours);

        vm.prank(player_1);
        token.transfer(admin, 2_000e6);

        assertEq(token.balanceOf(admin), 4_000e6);
        vm.warp(block.timestamp + 20 minutes);

        vm.prank(player_2);
        token.transfer(admin, 2_000e6);

        assertEq(token.balanceOf(admin), 6_000e6);
        vm.warp(block.timestamp + 4 hours);

        vm.prank(player_3);
        token.transfer(admin, 1_000e6);

        assertEq(token.balanceOf(admin), 7_000e6);
        vm.warp(block.timestamp + 233 minutes);

        vm.prank(player_4);
        token.transfer(admin, 1_000e6);

        assertEq(token.balanceOf(admin), 8_000e6);
        vm.warp(block.timestamp + 3 hours);

        vm.startPrank(admin);

        token.approve(address(bankroll), 1_000_000_000e6);

        bankroll.creditAndDebit(2_000e6, 2_500e6, operator, player_0);
        assertEq(token.balanceOf(address(dgEscrow)), 2_500e6);

        bankroll.creditAndDebit(2_000e6, 3_000e6, operator, player_1);
        assertEq(token.balanceOf(address(dgEscrow)), 5_500e6);

        bankroll.creditAndDebit(2_000e6, 2_200e6, operator, player_2);
        assertEq(token.balanceOf(address(dgEscrow)), 7_700e6);

        bankroll.creditAndDebit(1_000e6, 20e6, operator, player_3);

        // player_4 lost it all...
        bankroll.credit(1_000e6, operator);

        DGDataTypes.EscrowEntry memory entry_0 = DGDataTypes.EscrowEntry(
            address(bankroll),
            operator,
            player_0,
            address(token),
            block.timestamp,
            0
        );
        
        DGDataTypes.EscrowEntry memory entry_1 = DGDataTypes.EscrowEntry(
            address(bankroll),
            operator,
            player_1,
            address(token),
            block.timestamp,
            1
        );

        DGDataTypes.EscrowEntry memory entry_2 = DGDataTypes.EscrowEntry(
            address(bankroll),
            operator,
            player_2,
            address(token),
            block.timestamp,
            2
        );
        
        DGDataTypes.EscrowEntry memory faultyEntry = DGDataTypes.EscrowEntry(
            address(bankroll),
            operator,
            player_2,
            address(token),
            block.timestamp,
            0
        );

        vm.expectRevert(DGErrors.NOTHING_TO_CLAIM.selector);
        dgEscrow.revertFunds(abi.encode(faultyEntry));

        vm.expectRevert(DGErrors.NOTHING_TO_CLAIM.selector);
        dgEscrow.releaseFunds(abi.encode(faultyEntry));

        // Revert player 0s funds back into the bankroll
        dgEscrow.revertFunds(abi.encode(entry_0));

        // release player 1s funds to them
        dgEscrow.releaseFunds(abi.encode(entry_1));

        // leave player 2s funds unaddressed
        vm.warp(block.timestamp + 1 days);

        vm.stopPrank();

        // trying to claim before event period is passed
        vm.expectRevert(DGErrors.EVENT_PERIOD_NOT_PASSED.selector);
        vm.prank(player_2);
        dgEscrow.claimUnaddressed(abi.encode(entry_2));

        vm.warp(block.timestamp + 1 weeks);

        vm.expectRevert(DGErrors.UNAUTHORIZED_CLAIM.selector);
        // Trying to claim with the wrong player (player_2 is the correctt claimer)
        vm.prank(player_1);
        dgEscrow.claimUnaddressed(abi.encode(entry_2));

        vm.prank(player_2);
        dgEscrow.claimUnaddressed(abi.encode(entry_2));
    }
}