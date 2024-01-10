// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/GameBankroll.sol";
import "../test/mock/MockToken.sol";

contract GameBankrollTest is Test {

    address manager;
    address investorOne;
    address investorTwo;
    address player;

    GameBankroll gameBankroll;
    MockToken token;

    function setUp() public {
        manager = address(0x1);
        investorOne = address(0x2);
        investorTwo = address(0x3);
        player = address(0x4);
        token = new MockToken("token", "MTK");
        gameBankroll = new GameBankroll(manager, address(token));

        token.mint(investorOne, 1000_000);
        token.mint(investorTwo, 1000_000);
        token.mint(manager, 1000_000);
    }

    function test_depositFunds() public {

        assertEq(token.balanceOf(address(gameBankroll)), 0);

        // investor one deposits 1000_000
        vm.startPrank(investorOne);
        token.approve(address(gameBankroll), 1000_000);
        gameBankroll.depositFunds(1000_000);
        assertEq(gameBankroll.depositedOf(address(investorOne)), 1000_000);
        assertEq(gameBankroll.sharesOf(address(investorOne)), 1000_000);
        vm.stopPrank();

        assertEq(gameBankroll.totalSupply(), 1000_000);
        assertEq(token.balanceOf(address(gameBankroll)), 1000_000);

        // investor two deposits 1000_000
        vm.startPrank(investorTwo);
        token.approve(address(gameBankroll), 1000_000);
        gameBankroll.depositFunds(1000_000);
        assertEq(gameBankroll.depositedOf(address(investorTwo)), 1000_000);
        assertEq(gameBankroll.sharesOf(address(investorTwo)), 1000_000);
        vm.stopPrank();

        assertEq(gameBankroll.totalSupply(), 2000_000);
        assertEq(token.balanceOf(address(gameBankroll)), 2000_000);
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
}
