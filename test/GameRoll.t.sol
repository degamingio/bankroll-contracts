// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/GameRoll.sol";
import "../test/mock/MockToken.sol";

contract GameRollTest is Test {

    address manager;
    address investorOne;
    address investorTwo;
    address player;

    GameRoll gameRoll;
    MockToken token;

    function setUp() public {
        manager = address(0x1);
        investorOne = address(0x2);
        investorTwo = address(0x3);
        player = address(0x4);
        token = new MockToken("token", "MTK");
        gameRoll = new GameRoll(manager, address(token));

        token.mint(investorOne, 1000_000);
        token.mint(investorTwo, 1000_000);
        token.mint(manager, 1000_000);
    }

    function test_depositFunds() public {

        assertEq(token.balanceOf(address(gameRoll)), 0);

        // investor one deposits 1000_000
        vm.startPrank(investorOne);
        token.approve(address(gameRoll), 1000_000);
        gameRoll.depositFunds(1000_000);
        assertEq(gameRoll.depositedOf(address(investorOne)), 1000_000);
        assertEq(gameRoll.sharesOf(address(investorOne)), 1000_000);
        vm.stopPrank();

        assertEq(gameRoll.totalSupply(), 1000_000);
        assertEq(token.balanceOf(address(gameRoll)), 1000_000);

        // investor two deposits 1000_000
        vm.startPrank(investorTwo);
        token.approve(address(gameRoll), 1000_000);
        gameRoll.depositFunds(1000_000);
        assertEq(gameRoll.depositedOf(address(investorTwo)), 1000_000);
        assertEq(gameRoll.sharesOf(address(investorTwo)), 1000_000);
        vm.stopPrank();

        assertEq(gameRoll.totalSupply(), 2000_000);
        assertEq(token.balanceOf(address(gameRoll)), 2000_000);
    }

     function test_withdrawAll() public {
        vm.startPrank(investorOne);
        token.approve(address(gameRoll), 1000_000);
        gameRoll.depositFunds(1000_000);
        vm.stopPrank();

        vm.startPrank(investorTwo);
        token.approve(address(gameRoll), 1000_000);
        gameRoll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(gameRoll)), 2000_000);
        assertEq(token.balanceOf(address(investorOne)), 0);
        assertEq(token.balanceOf(address(investorTwo)), 0);

        vm.prank(investorOne);
        gameRoll.withdrawAll();
        
        assertEq(token.balanceOf(address(gameRoll)), 1000_000);
        assertEq(token.balanceOf(address(investorOne)), 1000_000);
        assertEq(token.balanceOf(address(investorTwo)), 0);
    }

    function test_debit() public {

        vm.startPrank(investorOne);
        token.approve(address(gameRoll), 1000_000);
        gameRoll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(gameRoll)), 1000_000);

        vm.prank(manager);
        gameRoll.debit(player, 500_000);

        assertEq(token.balanceOf(address(gameRoll)), 500_000);
        assertEq(token.balanceOf(address(player)), 500_000);
        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(gameRoll.sharesOf(address(investorOne)), 1000_000);
        assertEq(gameRoll.getAmount(address(investorOne)), 500_000);

    }

    function test_credit() public {

        vm.startPrank(investorOne);
        token.approve(address(gameRoll), 1000_000);
        gameRoll.depositFunds(1000_000);
        vm.stopPrank();

        // player lost 500_000

        vm.startPrank(manager);
        token.approve(address(gameRoll), 500_000);
        token.transfer(address(gameRoll), 500_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(gameRoll)), 1500_000);
        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(gameRoll.sharesOf(address(investorOne)), 1000_000);
        assertEq(gameRoll.getAmount(address(investorOne)), 1500_000);

    }
}
