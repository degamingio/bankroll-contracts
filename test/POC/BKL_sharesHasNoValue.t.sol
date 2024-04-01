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

/* Mock Contracts */
import {MockToken} from "test/mock/MockToken.sol";

contract BKL_sharesHasNoValue is Test {
    MockToken public mockToken;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;
    DGBankrollFactory public dgBankrollFactory;
    TransparentUpgradeableProxy public bankrollProxy;

    ProxyAdmin public proxyAdmin;

    address admin;
    address deGaming;
    address operator;

    address[] operators;
    address[] lps;

    uint256 maxRisk = 10_000;
    uint256 threshold = 10_000;

    function setUp() public {
        admin = address(0x1);
        deGaming = address(0x2);
        operator = address(0x3);

        operators = [ 
            address(0x55), 
            address(0x56), 
            address(0x57),
            address(0x58),
            address(0x59),
            address(0x60)
        ];

        lps = [ 
            address(0x65), 
            address(0x66), 
            address(0x67),
            address(0x68),
            address(0x69),
            address(0x70)
        ];


        mockToken = new MockToken("Mock USDC", "mUSDC");

        dgBankrollFactory = new DGBankrollFactory();

        dgBankrollManager = new DGBankrollManager(deGaming);

        dgEscrow = new DGEscrow(1 weeks, address(dgBankrollManager));

        proxyAdmin = new ProxyAdmin();

        bankrollProxy = new TransparentUpgradeableProxy(
            address(new Bankroll()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Bankroll.initialize.selector,
                admin,
                address(mockToken),
                address(dgBankrollManager),
                address(dgEscrow),
                msg.sender,
                maxRisk,
                threshold
            )
        );

        bankroll = Bankroll(address(bankrollProxy));

        dgBankrollManager.grantRole(keccak256("ADMIN"), address(dgBankrollFactory));

        dgBankrollManager.grantRole(keccak256("ADMIN"), admin);

        vm.expectRevert(DGErrors.ADDRESS_NOT_A_CONTRACT.selector);
        dgBankrollManager.approveBankroll(admin, 650);
        
        dgBankrollManager.approveBankroll(address(bankroll), 650);

        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);

        mockToken.mint(admin, 1_000_000e6);

        vm.prank(admin);
    
        mockToken.approve(address(bankroll), 1_000_000e6);
    }

    function test_sharesHasNoValue() public {
        address bob = address(0x4);
        uint256 amount = 100e6;
        address player = address(0x6);

        mockToken.mint(bob, amount);

        // Bob deposits 100 USDC 
        vm.startPrank(bob);
        mockToken.approve(address(bankroll), amount);
        bankroll.depositFunds(amount);
        vm.stopPrank();

        // Admin debit 100 USDC to player
        vm.prank(admin);
        bankroll.debit(player, 100e6, operator);

        uint256 bobBalanceBefore = mockToken.balanceOf(bob);
        console.log("Balance before", bobBalanceBefore);

        // Bob withdraws its funds
        vm.startPrank(bob);
        bankroll.withdrawalStageOne(bankroll.sharesOf(bob));
        vm.warp(3);
        bankroll.withdrawalStageTwo();
        vm.stopPrank();

        uint256 bobBalanceAfter = mockToken.balanceOf(bob);
        console.log("Balance after", bobBalanceAfter);

        assertEq(bobBalanceAfter, bobBalanceBefore);
        assertEq(bobBalanceAfter, 0);
    }

        function test_sharesHasNoValueComplex() public {
        address bob = address(0x4);
        uint256 firstDepositAmount = 9177495602;
        uint256 creditAmount = 10e6;
        uint256 firstDebitAmount = 91807152217;
        uint256 secondDepositAmount = 804218615254233;
        uint256 secondDebitAmount = 25209163503495075613269;
        uint256 amountWithdraw = 10e6;
        address player = address(0x6);

        mockToken.mint(bob, firstDepositAmount + secondDepositAmount);

        // Bob deposits firstDepositAmount
        vm.startPrank(bob);
        mockToken.approve(address(bankroll), firstDepositAmount);
        bankroll.depositFunds(firstDepositAmount);
        vm.stopPrank();

        // Admin credit creditAmount
        vm.prank(admin);
        bankroll.credit(creditAmount, operator);

        // Admin debit firstDebitAmount
        vm.prank(admin);
        bankroll.debit(player, firstDebitAmount, operator);

        // Bob deposits secondDepositAmount
        vm.startPrank(bob);
        mockToken.approve(address(bankroll), secondDepositAmount);
        bankroll.depositFunds(secondDepositAmount);
        vm.stopPrank();

        // Admin debit secondDebitAmount
        vm.prank(admin);
        bankroll.debit(player, secondDebitAmount, operator);

        uint256 bobBalanceBefore = mockToken.balanceOf(bob);

        // Bob withdraws 10e6 shares ...
        vm.startPrank(bob);
        bankroll.withdrawalStageOne(amountWithdraw);
        vm.warp(3);
        bankroll.withdrawalStageTwo();
        vm.stopPrank();

        uint256 bobBalanceAfter = mockToken.balanceOf(bob);

        // ... and get back 0 tokens
        assertEq(bobBalanceAfter, bobBalanceBefore);
    }

}
    