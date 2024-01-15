// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/GameBankroll.sol";
import "../test/mock/MockToken.sol";

contract GameBankrollTest is Test {
    address admin;
    address manager;
    address investorOne;
    address investorTwo;
    address player;

    GameBankroll gameBankroll;
    MockToken token;

    function setUp() public {
        admin = address(0x1);
        manager = address(0x2);
        investorOne = address(0x3);
        investorTwo = address(0x4);
        player = address(0x5);
        token = new MockToken("token", "MTK");
        gameBankroll = new GameBankroll(admin, address(token));

        token.mint(investorOne, 1000_000);
        token.mint(investorTwo, 1000_000);
        token.mint(manager, 1000_000);

        vm.prank(admin);
        gameBankroll.setManager(manager, true);
    }

    function test_depositFunds() public {
        assertEq(token.balanceOf(address(gameBankroll)), 0);

        // investor one deposits 1000_000
        vm.startPrank(investorOne);
        token.approve(address(gameBankroll), 1000_000);
        gameBankroll.depositFunds(1000_000);
        assertEq(gameBankroll.investmentOf(address(investorOne)), 1000_000);
        assertEq(gameBankroll.sharesOf(address(investorOne)), 1000_000);
        vm.stopPrank();

        assertEq(gameBankroll.totalSupply(), 1000_000);
        assertEq(token.balanceOf(address(gameBankroll)), 1000_000);

        // investor two deposits 1000_000
        vm.startPrank(investorTwo);
        token.approve(address(gameBankroll), 1000_000);
        gameBankroll.depositFunds(1000_000);
        assertEq(gameBankroll.investmentOf(address(investorTwo)), 1000_000);
        assertEq(gameBankroll.sharesOf(address(investorTwo)), 1000_000);
        vm.stopPrank();

        assertEq(gameBankroll.totalSupply(), 2000_000);
        assertEq(token.balanceOf(address(gameBankroll)), 2000_000);
    }

    function test_depositFundsWithInvestorWhitelist() public {
        vm.prank(admin);
        gameBankroll.setPublic(false);

        // investor one deposits 1000_000
        vm.startPrank(investorOne);
        token.approve(address(gameBankroll), 1000_000);
        vm.expectRevert(0xdaf9dbc0); //FORBIDDEN()
        gameBankroll.depositFunds(1000_000);
        vm.stopPrank();

        vm.prank(admin);
        gameBankroll.setInvestorWhitelist(investorOne, true);

        vm.startPrank(investorOne);
        gameBankroll.depositFunds(1000_000);

        assertEq(gameBankroll.investmentOf(address(investorOne)), 1000_000);
        assertEq(gameBankroll.sharesOf(address(investorOne)), 1000_000);

        vm.stopPrank();
    }

    function test_withdrawAll() public {
        vm.startPrank(investorOne);
        token.approve(address(gameBankroll), 1000_000);
        gameBankroll.depositFunds(1000_000);
        vm.stopPrank();

        vm.startPrank(investorTwo);
        token.approve(address(gameBankroll), 1000_000);
        gameBankroll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(gameBankroll)), 2000_000);
        assertEq(token.balanceOf(address(investorOne)), 0);
        assertEq(token.balanceOf(address(investorTwo)), 0);

        vm.prank(investorOne);
        gameBankroll.withdrawAll();

        assertEq(token.balanceOf(address(gameBankroll)), 1000_000);
        assertEq(token.balanceOf(address(investorOne)), 1000_000);
        assertEq(token.balanceOf(address(investorTwo)), 0);
    }

    function test_debit() public {
        vm.startPrank(investorOne);
        token.approve(address(gameBankroll), 1000_000);
        gameBankroll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(gameBankroll)), 1000_000);

        vm.prank(manager);
        gameBankroll.debit(player, 500_000);

        assertEq(token.balanceOf(address(gameBankroll)), 500_000);
        assertEq(token.balanceOf(address(player)), 500_000);
        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(gameBankroll.sharesOf(address(investorOne)), 1000_000);
        assertEq(gameBankroll.getAmount(address(investorOne)), 500_000);
    }

    function test_debitInsufficientFunds() public {
        vm.startPrank(investorOne);
        token.approve(address(gameBankroll), 1000_000);
        gameBankroll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(gameBankroll)), 1000_000);

        vm.prank(manager);
        gameBankroll.debit(player, 5000_000);

        assertEq(token.balanceOf(address(gameBankroll)), 0);
        assertEq(token.balanceOf(address(player)), 1000_000);
        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(gameBankroll.sharesOf(address(investorOne)), 1000_000);
        assertEq(gameBankroll.getAmount(address(investorOne)), 0);
    }

    function test_credit() public {
        vm.startPrank(investorOne);
        token.approve(address(gameBankroll), 1000_000);
        gameBankroll.depositFunds(1000_000);
        vm.stopPrank();

        // player lost 500_000

        vm.startPrank(manager);
        token.approve(address(gameBankroll), 500_000);
        token.transfer(address(gameBankroll), 500_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(gameBankroll)), 1500_000);
        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(gameBankroll.sharesOf(address(investorOne)), 1000_000);
        assertEq(gameBankroll.getAmount(address(investorOne)), 1500_000);
    }

    function test_setInvestorWhitelist() public {
        assertEq(gameBankroll.investorWhitelist(investorOne), false);

        vm.prank(admin);
        gameBankroll.setInvestorWhitelist(investorOne, true);

        assertEq(gameBankroll.investorWhitelist(investorOne), true);
    }

    function test_setAdmin() public {
        assertEq(gameBankroll.admin(), admin);

        vm.prank(admin);
        gameBankroll.setAdmin(investorOne);

        assertEq(gameBankroll.admin(), investorOne);
    }

    function test_setManager() public {
        assertEq(gameBankroll.managers(manager), true);

        vm.prank(admin);
        gameBankroll.setManager(investorOne, true);

        assertEq(gameBankroll.managers(investorOne), true);
        assertEq(gameBankroll.managers(manager), true);

        vm.prank(admin);
        gameBankroll.setManager(manager, false);

        assertEq(gameBankroll.managers(manager), false);
    }

    function test_setPublic() public {
        assertEq(gameBankroll.isPublic(), true);

        vm.prank(admin);
        gameBankroll.setPublic(false);

        assertEq(gameBankroll.isPublic(), false);
    }
}
