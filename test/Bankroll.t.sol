// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Bankroll.sol";
import "../test/mock/MockToken.sol";

contract BankrollTest is Test {
    address admin;
    address manager;
    address investorOne;
    address investorTwo;
    address player;

    Bankroll bankroll;
    MockToken token;

    function setUp() public {
        admin = address(0x1);
        manager = address(0x2);
        investorOne = address(0x3);
        investorTwo = address(0x4);
        player = address(0x5);
        token = new MockToken("token", "MTK");
        bankroll = new Bankroll(admin, address(token));

        token.mint(investorOne, 1000_000);
        token.mint(investorTwo, 1000_000);
        token.mint(manager, 1000_000);

        vm.prank(admin);
        bankroll.setManager(manager, true);
    }

    function test_depositFunds() public {
        assertEq(token.balanceOf(address(bankroll)), 0);

        // investor one deposits 1000_000
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        assertEq(bankroll.investmentOf(address(investorOne)), 1000_000);
        assertEq(bankroll.sharesOf(address(investorOne)), 1000_000);
        vm.stopPrank();

        assertEq(bankroll.totalSupply(), 1000_000);
        assertEq(token.balanceOf(address(bankroll)), 1000_000);

        // investor two deposits 1000_000
        vm.startPrank(investorTwo);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        assertEq(bankroll.investmentOf(address(investorTwo)), 1000_000);
        assertEq(bankroll.sharesOf(address(investorTwo)), 1000_000);
        vm.stopPrank();

        assertEq(bankroll.totalSupply(), 2000_000);
        assertEq(token.balanceOf(address(bankroll)), 2000_000);
    }

    function test_depositFundsWithInvestorWhitelist() public {
        vm.prank(admin);
        bankroll.setPublic(false);

        // investor one deposits 1000_000
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1000_000);
        vm.expectRevert(0xdaf9dbc0); //reverts: FORBIDDEN()
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        vm.prank(admin);
        bankroll.setInvestorWhitelist(investorOne, true);

        vm.startPrank(investorOne);
        bankroll.depositFunds(1000_000);

        assertEq(bankroll.investmentOf(address(investorOne)), 1000_000);
        assertEq(bankroll.sharesOf(address(investorOne)), 1000_000);

        vm.stopPrank();
    }

    function test_withdrawAll() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        vm.startPrank(investorTwo);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(bankroll)), 2000_000);
        assertEq(token.balanceOf(address(investorOne)), 0);
        assertEq(token.balanceOf(address(investorTwo)), 0);

        vm.prank(investorOne);
        bankroll.withdrawAll();

        assertEq(token.balanceOf(address(bankroll)), 1000_000);
        assertEq(token.balanceOf(address(investorOne)), 1000_000);
        assertEq(token.balanceOf(address(investorTwo)), 0);
    }

    function test_debit() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(bankroll)), 1000_000);

        vm.prank(manager);
        bankroll.debit(player, 500_000);

        assertEq(token.balanceOf(address(bankroll)), 500_000);
        assertEq(token.balanceOf(address(player)), 500_000);
        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(bankroll.sharesOf(address(investorOne)), 1000_000);
        assertEq(bankroll.getAmount(address(investorOne)), 500_000);
    }

    function test_debitInsufficientFunds() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(bankroll)), 1000_000);

        vm.prank(manager);
        bankroll.debit(player, 5000_000);

        assertEq(token.balanceOf(address(bankroll)), 0);
        assertEq(token.balanceOf(address(player)), 1000_000);
        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(bankroll.sharesOf(address(investorOne)), 1000_000);
        assertEq(bankroll.getAmount(address(investorOne)), 0);
    }

    function test_credit() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        vm.startPrank(manager);
        token.approve(address(bankroll), 500_000);
        token.transfer(address(bankroll), 500_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(bankroll)), 1500_000);
        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(bankroll.sharesOf(address(investorOne)), 1000_000);
        assertEq(bankroll.getAmount(address(investorOne)), 1500_000);
    }

    function test_setInvestorWhitelist() public {
        assertEq(bankroll.investorWhitelist(investorOne), false);

        vm.prank(admin);
        bankroll.setInvestorWhitelist(investorOne, true);

        assertEq(bankroll.investorWhitelist(investorOne), true);
    }

    function test_setAdmin() public {
        assertEq(bankroll.admin(), admin);

        vm.prank(admin);
        bankroll.setAdmin(investorOne);

        assertEq(bankroll.admin(), investorOne);
    }

    function test_setManager() public {
        assertEq(bankroll.managers(manager), true);

        vm.prank(admin);
        bankroll.setManager(investorOne, true);

        assertEq(bankroll.managers(investorOne), true);
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
}
