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

contract BKL_depositFundsDos is Test {
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

    function test_dosDepositFunds() public {
        address bob = address(0x4);
        address alice = address(0x5);
        address player = address(0x6);

        mockToken.mint(bob, 1e6);
        mockToken.mint(alice, 1e6);

        // Bob deposits 1 USDC
        vm.startPrank(bob);
        mockToken.approve(address(bankroll), 1e6);
        bankroll.depositFunds(1e6);
        vm.stopPrank();

        // Admin credit 1 USDC to player
        vm.prank(admin);
        bankroll.debit(player, 1e6, operator);
        
        // Alice deposits 1 USDC
        vm.startPrank(alice);
        mockToken.approve(address(bankroll), 1e6);

        // panic: division or modulo by zero
        vm.expectRevert();
        bankroll.depositFunds(1e6);
        vm.stopPrank();
    }

}
    