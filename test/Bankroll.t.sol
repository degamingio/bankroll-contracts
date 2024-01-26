// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Bankroll.sol";
import "../test/mock/MockToken.sol";

contract BankrollTest is Test {
    address admin;
    address manager;
    address lpOne;
    address lpTwo;
    address player;

    Bankroll bankroll;
    MockToken token;

    function setUp() public {
        admin = address(0x1);
        manager = address(0x2);
        lpOne = address(0x3);
        lpTwo = address(0x4);
        player = address(0x5);
        token = new MockToken("token", "MTK");
        bankroll = new Bankroll(admin, address(token));

        token.mint(lpOne, 1_000_000);
        token.mint(lpTwo, 1_000_000);
        token.mint(manager, 1_000_000);

        vm.prank(admin);
        bankroll.setManager(manager, true);
    }

    function test_depositFunds() public {
        assertEq(bankroll.liquidity(), 0);

        // lp one deposits 1000_000
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        assertEq(bankroll.depositOf(address(lpOne)), 1_000_000);
        assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000);
        vm.stopPrank();

        assertEq(bankroll.totalSupply(), 1_000_000);
        assertEq(bankroll.liquidity(), 1_000_000);

        // lp two deposits 1000_000
        vm.startPrank(lpTwo);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        assertEq(bankroll.depositOf(address(lpTwo)), 1_000_000);
        assertEq(bankroll.sharesOf(address(lpTwo)), 1_000_000);
        vm.stopPrank();

        assertEq(bankroll.totalSupply(), 2_000_000);
        assertEq(bankroll.liquidity(), 2_000_000);
    }

    function test_depositFundsWithInvestorWhitelist() public {
        vm.prank(admin);
        bankroll.setPublic(false);

        // lp one deposits 1000_000
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000);
        vm.expectRevert(0xdaf9dbc0); //reverts: FORBIDDEN()
        bankroll.depositFunds(1_000_000);
        vm.stopPrank();

        vm.prank(admin);
        bankroll.setInvestorWhitelist(lpOne, true);

        vm.startPrank(lpOne);
        bankroll.depositFunds(1_000_000);

        assertEq(bankroll.depositOf(address(lpOne)), 1_000_000);
        assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000);

        vm.stopPrank();
    }

    function test_withdrawAll() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        vm.stopPrank();

        vm.startPrank(lpTwo);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        vm.stopPrank();

        // funds have been deposited
        assertEq(bankroll.liquidity(), 2_000_000);
        assertEq(token.balanceOf(address(lpOne)), 0);
        assertEq(token.balanceOf(address(lpTwo)), 0);

        // initial deposit
        assertEq(bankroll.depositOf(address(lpOne)), 1_000_000);
        assertEq(bankroll.depositOf(address(lpTwo)), 1_000_000);

        // zero in profits because no fees have been collected
        assertEq(bankroll.getLpProfit(address(lpOne)), 0);
        assertEq(bankroll.getLpProfit(address(lpTwo)), 0);

        vm.startPrank(lpOne);
        bankroll.withdrawAll();
        vm.stopPrank();

        // funds have been deposited
        assertEq(bankroll.liquidity(), 1_000_000);
        assertEq(token.balanceOf(address(lpOne)), 1_000_000);
        assertEq(token.balanceOf(address(lpTwo)), 0);
    }

    function test_debit() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        vm.stopPrank();

        // bankroll has 1_000_000
        assertEq(token.balanceOf(address(bankroll)), 1_000_000);
        assertEq(bankroll.liquidity(), 1_000_000);

        // lpOne has 1_000_000 shares
        assertEq(token.balanceOf(address(lpOne)), 0);
        assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000);

        // pay player 500_000
        vm.prank(manager);
        bankroll.debit(player, 500_000);

        // bankroll now has 500_000
        assertEq(bankroll.liquidity(), 500_000);

        // player now has 500_000
        assertEq(token.balanceOf(address(player)), 500_000);

        // lpOne now has shares worth only 500_000
        assertEq(bankroll.getLpValue(address(lpOne)), 500_000);
    }

    function test_debitInsufficientFunds() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(bankroll.liquidity(), 1000_000);

        vm.prank(manager);
        bankroll.debit(player, 5000_000);

        assertEq(bankroll.liquidity(), 0);
        assertEq(token.balanceOf(address(player)), 1000_000);
        assertEq(token.balanceOf(address(lpOne)), 0);

        assertEq(bankroll.sharesOf(address(lpOne)), 1000_000);
        assertEq(bankroll.getLpValue(address(lpOne)), 0);
    }

    function test_credit() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        vm.startPrank(manager);
        token.approve(address(bankroll), 500_000);
        bankroll.credit(500_000);
        vm.stopPrank();

        // profit is not available for LPs before managers has claimed it
        assertEq(bankroll.liquidity(), 1000_000);
        assertEq(bankroll.managersProfit(), 500_000);
        assertEq(bankroll.lpsProfit(), 0);
    }

    function test_claimProfit() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        vm.startPrank(manager);
        token.approve(address(bankroll), 100_000);
        bankroll.credit(100_000);
        vm.stopPrank();

        // profit is NOT available for LPs before managers has claimed it
        assertEq(bankroll.liquidity(), 1000_000);
        assertEq(bankroll.managersProfit(), 100_000);
        assertEq(bankroll.lpsProfit(), 0);

        // claim profit
        vm.startPrank(manager);
        bankroll.claimProfit();
        vm.stopPrank();

        // managers should have claimed profit
        assertEq(bankroll.managersProfit(), 0);
        assertEq(bankroll.profitOf(address(manager)), 0);

        // profit is NOW available for LPs
        assertEq(bankroll.lpsProfit(), 6_500);
        assertEq(bankroll.liquidity(), 1006_500);
        assertEq(bankroll.getLpValue(lpOne), 1006_500);

        // widthdraw all funds
        vm.prank(lpOne);
        bankroll.withdrawAll();

        // lpOne should have claimed profit
        assertEq(bankroll.getLpStake(address(lpOne)), 0);
        assertEq(bankroll.getLpProfit(address(lpOne)), 0);
        assertEq(bankroll.getLpValue(address(lpOne)), 0);
    }

    function test_claimProfitWhenNegative() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 100_000);
        bankroll.depositFunds(100_000);
        vm.stopPrank();

        vm.prank(manager);
        bankroll.debit(player, 10_000);

        // manager cannot claim profit when negative
        vm.prank(manager);
        vm.expectRevert(0xb5b9a8e6); //reverts: NO_PROFIT()
        bankroll.claimProfit();

        // lpOne investment should have decreased
        assertEq(bankroll.getLpStake(address(lpOne)), 10_000);
        assertEq(bankroll.getLpProfit(address(lpOne)), -10_000);
        assertEq(bankroll.getLpValue(address(lpOne)), 90_000);
    }

    function test_setInvestorWhitelist() public {
        assertEq(bankroll.lpWhitelist(lpOne), false);

        vm.prank(admin);
        bankroll.setInvestorWhitelist(lpOne, true);

        assertEq(bankroll.lpWhitelist(lpOne), true);
    }

    function test_setAdmin() public {
        assertEq(bankroll.admin(), admin);

        vm.prank(admin);
        bankroll.setAdmin(lpOne);

        assertEq(bankroll.admin(), lpOne);
    }

    function test_setManager() public {
        assertEq(bankroll.managers(manager), true);

        vm.prank(admin);
        bankroll.setManager(lpOne, true);

        assertEq(bankroll.managers(lpOne), true);
        assertEq(bankroll.managers(manager), true);

        vm.prank(admin);
        bankroll.setManager(manager, false);

        assertEq(bankroll.managers(manager), false);
    }

    function test_setPublic() public {
        assertEq(bankroll.isPublic(), true);

        vm.prank(admin);
        bankroll.setPublic(false);

        assertEq(bankroll.isPublic(), false);
    }

    function test_setFee() public {
        assertEq(bankroll.lpFee(), 650);

        vm.prank(admin);
        bankroll.setLpFee(10);

        assertEq(bankroll.lpFee(), 10);
    }

    function test_getLpStake() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 10_000);
        bankroll.depositFunds(10_000);
        vm.stopPrank();

        vm.startPrank(lpTwo);
        token.approve(address(bankroll), 10_000);
        bankroll.depositFunds(10_000);
        vm.stopPrank();

        assertEq(bankroll.getLpStake(address(lpOne)), 5000);
        assertEq(bankroll.getLpStake(address(lpTwo)), 5000);

        vm.startPrank(lpOne);
        token.approve(address(bankroll), 10_000);
        bankroll.depositFunds(10_000);
        vm.stopPrank();

        assertEq(bankroll.getLpStake(address(lpOne)), 6666);
        assertEq(bankroll.getLpStake(address(lpTwo)), 3333);
    }
}
