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

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/* Mock Contracts */
import {MockToken} from "test/mock/MockToken.sol";


contract BankrollTest is Test {
    address admin;
    address operator;
    address lpOne;
    address lpTwo;
    address player;
    address owner;
    TransparentUpgradeableProxy public bankrollProxy;

    ProxyAdmin public proxyAdmin;

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    Bankroll public bankroll;
    MockToken public token;

    function setUp() public {
        admin = address(0x1);
        operator = address(0x2);
        lpOne = address(0x3);
        lpTwo = address(0x4);
        player = address(0x5);
        owner = address(0x6);
        uint256 maxRisk = 10_000;

        dgBankrollFactory = new DGBankrollFactory();

        dgBankrollManager = new DGBankrollManager(admin);
        token = new MockToken("token", "MTK");

        proxyAdmin = new ProxyAdmin(msg.sender);

        bankrollProxy = new TransparentUpgradeableProxy(
            address(new Bankroll()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Bankroll.initialize.selector,
                admin,
                address(token),
                address(dgBankrollManager),
                owner,
                maxRisk
            )
        );

        bankroll = Bankroll(address(bankrollProxy));

        token.mint(lpOne, 1_000_000e6);
        token.mint(lpTwo, 1_000_000e6);
        token.mint(admin, 1_000_000e6);

        dgBankrollManager.addOperator(operator);
        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);
        dgBankrollManager.approveBankroll(address(bankroll), 0);
    }

    function test_depositFunds() public {
        assertEq(bankroll.liquidity(), 0);

        // lp one deposits 1000_000
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        assertEq(bankroll.depositOf(address(lpOne)), 1_000_000e6);
        assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000e6);
        vm.stopPrank();

        assertEq(bankroll.totalSupply(), 1_000_000e6);
        assertEq(bankroll.liquidity(), 1_000_000e6);

        // lp two deposits 1000_000
        vm.startPrank(lpTwo);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        assertEq(bankroll.depositOf(address(lpTwo)), 1_000_000e6);
        assertEq(bankroll.sharesOf(address(lpTwo)), 1_000_000e6);
        vm.stopPrank();

        assertEq(bankroll.totalSupply(), 2_000_000e6);
        assertEq(bankroll.liquidity(), 2_000_000e6);
    }

    function test_depositFundsWithInvestorWhitelist() public {
        vm.prank(admin);
        bankroll.setPublic(DGDataTypes.LpIs.WHITELISTED);

        // lp one deposits 1000_000
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        vm.expectRevert(DGErrors.LP_IS_NOT_WHITELISTED.selector); //reverts: FORBIDDEN()
        bankroll.depositFunds(1_000_000e6);
        vm.stopPrank();

        vm.prank(admin);
        bankroll.setInvestorWhitelist(lpOne, true);

        vm.startPrank(lpOne);
        bankroll.depositFunds(1_000_000e6);

        assertEq(bankroll.depositOf(address(lpOne)), 1_000_000e6);
        assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000e6);

        vm.stopPrank();
    }

    function test_withdrawAll() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        vm.stopPrank();

        vm.startPrank(lpTwo);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        vm.stopPrank();

        // funds have been deposited
        assertEq(bankroll.liquidity(), 2_000_000e6);
        assertEq(token.balanceOf(address(lpOne)), 0);
        assertEq(token.balanceOf(address(lpTwo)), 0);

        // initial deposit
        assertEq(bankroll.depositOf(address(lpOne)), 1_000_000e6);
        assertEq(bankroll.depositOf(address(lpTwo)), 1_000_000e6);

        // zero in profits because no fees have been collected
        assertEq(bankroll.getLpProfit(address(lpOne)), 0);
        assertEq(bankroll.getLpProfit(address(lpTwo)), 0);

        vm.startPrank(lpOne);
        bankroll.withdrawAll();
        vm.stopPrank();

        // funds have been deposited
        assertEq(bankroll.liquidity(), 1_000_000e6);
        assertEq(token.balanceOf(address(lpOne)), 1_000_000e6);
        assertEq(token.balanceOf(address(lpTwo)), 0);
    }

    function test_withdraw_(uint256 _toHighAmount, uint256 _amountToWithdraw) public {
        vm.assume(_toHighAmount > 1_000_000e6);
        vm.assume(_amountToWithdraw < 500_000e6);

        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        vm.stopPrank();

        assertEq(bankroll.depositOf(address(lpOne)), 1_000_000e6);

        vm.prank(lpOne);
        vm.expectRevert(DGErrors.LP_REQUESTED_AMOUNT_OVERFLOW.selector);
        bankroll.withdraw(_toHighAmount);

        vm.prank(lpOne);
        bankroll.withdraw(_amountToWithdraw);

        assertEq(token.balanceOf(address(bankroll)), 1_000_000e6 - _amountToWithdraw);
    }

    function test_debit() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        vm.stopPrank();

        // bankroll has 1_000_000
        assertEq(token.balanceOf(address(bankroll)), 1_000_000e6);
        assertEq(bankroll.liquidity(), 1_000_000e6);

        // lpOne has 1_000_000 shares
        assertEq(token.balanceOf(address(lpOne)), 0);
        assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000e6);

        // pay player 500_000
        vm.prank(admin);
        bankroll.debit(player, 500_000e6, operator);

        // bankroll now has 500_000
        assertEq(bankroll.liquidity(), 500_000e6);

        // player now has 500_000
        assertEq(token.balanceOf(address(player)), 500_000e6);

        // lpOne now has shares worth only 500_000
        assertEq(bankroll.getLpValue(address(lpOne)), 500_000e6);
    }

    function test_debitInsufficientFunds() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        vm.stopPrank();

        assertEq(bankroll.liquidity(), 1_000_000e6);

        vm.prank(admin);
        bankroll.debit(player, 5000_000e6, operator);

        assertEq(bankroll.liquidity(), 0);
        assertEq(token.balanceOf(address(player)), 1_000_000e6);
        assertEq(token.balanceOf(address(lpOne)), 0);

        assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000e6);
        assertEq(bankroll.getLpValue(address(lpOne)), 0);
    }

    function test_credit() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        vm.stopPrank();

        vm.startPrank(admin);
        token.approve(address(bankroll), 500_000e6);
        bankroll.credit(500_000e6, operator);
        vm.stopPrank();

        // profit is not available for LPs before managers has claimed it
        assertEq(bankroll.liquidity(), 1_000_000e6);
        assertEq(bankroll.GGR(), 500_000e6);
        //assertEq(bankroll.lpsProfit(), 0);
    }

    function test_setInvestorWhitelist() public {
        assertEq(bankroll.lpWhitelist(lpOne), false);

        vm.prank(admin);
        bankroll.setInvestorWhitelist(lpOne, true);

        assertEq(bankroll.lpWhitelist(lpOne), true);
    }

    function test_updateAdmin(address _newAdmin) public {
        vm.assume(_newAdmin != address(0));
        vm.assume(_newAdmin != admin);
        vm.assume(!_isContract(_newAdmin));

        token.mint(_newAdmin, 10e6);

        vm.prank(_newAdmin);
        token.approve(address(bankroll), 10e6);
        vm.expectRevert();
        bankroll.credit(10e6, operator);
        vm.stopPrank(); 
     
        vm.prank(owner);
        bankroll.updateAdmin(admin, _newAdmin);
        
        vm.startPrank(_newAdmin);
        token.approve(address(bankroll), 10e6);
        bankroll.credit(10e6, operator);
        vm.stopPrank();
    }

    function test_setPublic() public {
        assertEq(uint256(bankroll.lpIs()), 0);

        vm.prank(admin);
        bankroll.setPublic(DGDataTypes.LpIs.WHITELISTED);

        assertEq(uint256(bankroll.lpIs()), 1);
    }

    function test_getLpStake() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 10_000e6);
        bankroll.depositFunds(10_000e6);
        vm.stopPrank();

        vm.startPrank(lpTwo);
        token.approve(address(bankroll), 10_000e6);
        bankroll.depositFunds(10_000e6);
        vm.stopPrank();

        assertEq(bankroll.getLpStake(address(lpOne)), 5_000);
        assertEq(bankroll.getLpStake(address(lpTwo)), 5_000);

        console.logUint(bankroll.getLpStake(address(lpOne)));

        vm.startPrank(lpOne);
        token.approve(address(bankroll), 10_000e6);
        bankroll.depositFunds(10_000e6);
        vm.stopPrank();

        assertEq(bankroll.getLpStake(address(lpOne)), 6_666);
        assertEq(bankroll.getLpStake(address(lpTwo)), 3_333);
    }

    function test_minimumLp(uint256 _newLpMinimum, uint256 _toLittle, uint256 _enough) public {
        vm.assume(_toLittle < 250_000e6);
        vm.assume(_newLpMinimum < 500_000e6);
        vm.assume(_enough < 750_000e6);
        vm.assume(_toLittle < _newLpMinimum);
        vm.assume(_enough > _newLpMinimum);

        token.mint(lpOne, _enough * 2);

        vm.prank(admin);
        bankroll.setMinimumLp(_newLpMinimum);

        vm.startPrank(lpOne);

        token.approve(address(bankroll), _enough * 2);

        vm.expectRevert(DGErrors.DEPOSITION_TO_LOW.selector);
        bankroll.depositFunds(_toLittle);

        bankroll.depositFunds(_enough);
        vm.stopPrank();

        vm.prank(admin);
        bankroll.setMinimumLPStatus(false);

        vm.prank(lpOne);
        bankroll.depositFunds(_toLittle);

    }

    function test_printErrors() public view {
        // 0x89ae3f9a
        console.logBytes4(DGErrors.ADDRESS_DOES_NOT_HOLD_ROLE.selector);
        
        // 0x5c2a0858
        console.logBytes4(DGErrors.ADDRESS_NOT_A_CONTRACT.selector);
        
        // 0x192498bf
        console.logBytes4(DGErrors.ADDRESS_NOT_A_WALLET.selector);
        
        // 0x85ef85ac
        console.logBytes4(DGErrors.BANKROLL_NOT_APPROVED.selector);
        
        // 0x2220bdd0
        console.logBytes4(DGErrors.DEPOSITION_TO_LOW.selector);
        
        // 0x2d03b3fd
        console.logBytes4(DGErrors.EVENT_PERIOD_NOT_PASSED.selector);
        
        // 0x1f22f3b3
        console.logBytes4(DGErrors.LP_IS_NOT_WHITELISTED.selector);
        
        // 0xf792d5d9
        console.logBytes4(DGErrors.LP_REQUESTED_AMOUNT_OVERFLOW.selector);
        
        // 0xb717644a
        console.logBytes4(DGErrors.MAXRISK_TO_HIGH.selector);
        
        // 0x59184bad
        console.logBytes4(DGErrors.NO_LP_ACCESS_PERMISSION.selector);
        
        // 0xf202cc93
        console.logBytes4(DGErrors.NOT_AN_OPERATOR.selector);
        
        // 0x76914729
        console.logBytes4(DGErrors.NOTHING_TO_CLAIM.selector);
        
        // 0x6c07c0e7
        console.logBytes4(DGErrors.OPERATOR_ALREADY_ADDED_TO_BANKROLL.selector);
        
        // 0x341e934a
        console.logBytes4(DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL.selector);
        
        // 0xb0647df7
        console.logBytes4(DGErrors.TO_HIGH_FEE.selector);
    }

    function _isContract(address _address) internal view returns (bool _isAddressContract) {
        uint256 size;

        assembly {
            size := extcodesize(_address)
        }

        _isAddressContract = size > 0;
    }
}
