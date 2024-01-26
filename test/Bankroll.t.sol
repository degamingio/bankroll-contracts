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

        token.mint(investorOne, 1_000_000);
        token.mint(investorTwo, 1_000_000);
        token.mint(manager, 1_000_000);

        vm.prank(admin);
        bankroll.setManager(manager, true);
    }

    function test_depositFunds() public {
        assertEq(bankroll.liquidity(), 0);

        // investor one deposits 1000_000
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        assertEq(bankroll.depositOf(address(investorOne)), 1_000_000);
        assertEq(bankroll.sharesOf(address(investorOne)), 1_000_000);
        vm.stopPrank();

        assertEq(bankroll.totalSupply(), 1_000_000);
        assertEq(bankroll.liquidity(), 1_000_000);

        // investor two deposits 1000_000
        vm.startPrank(investorTwo);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        assertEq(bankroll.depositOf(address(investorTwo)), 1_000_000);
        assertEq(bankroll.sharesOf(address(investorTwo)), 1_000_000);
        vm.stopPrank();

        assertEq(bankroll.totalSupply(), 2_000_000);
        assertEq(bankroll.liquidity(), 2_000_000);
    }

    function test_depositFundsWithInvestorWhitelist() public {
        vm.prank(admin);
        bankroll.setPublic(false);

        // investor one deposits 1000_000
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1_000_000);
        vm.expectRevert(0xdaf9dbc0); //reverts: FORBIDDEN()
        bankroll.depositFunds(1_000_000);
        vm.stopPrank();

        vm.prank(admin);
        bankroll.setInvestorWhitelist(investorOne, true);

        vm.startPrank(investorOne);
        bankroll.depositFunds(1_000_000);

        assertEq(bankroll.depositOf(address(investorOne)), 1_000_000);
        assertEq(bankroll.sharesOf(address(investorOne)), 1_000_000);

        vm.stopPrank();
    }

    function test_withdrawAll() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        vm.stopPrank();

        vm.startPrank(investorTwo);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        vm.stopPrank();

        // funds have been deposited
        assertEq(bankroll.liquidity(), 2_000_000);
        assertEq(token.balanceOf(address(investorOne)), 0);
        assertEq(token.balanceOf(address(investorTwo)), 0);

        // initial deposit
        assertEq(bankroll.depositOf(address(investorOne)), 1_000_000);
        assertEq(bankroll.depositOf(address(investorTwo)), 1_000_000);

        // zero in profits because no fees have been collected
        assertEq(bankroll.getInvestorProfit(address(investorOne)), 0);
        assertEq(bankroll.getInvestorProfit(address(investorTwo)), 0);

        vm.startPrank(investorOne);
        bankroll.withdrawAll();
        vm.stopPrank();

        // funds have been deposited
        assertEq(bankroll.liquidity(), 1_000_000);
        assertEq(token.balanceOf(address(investorOne)), 1_000_000);
        assertEq(token.balanceOf(address(investorTwo)), 0);
    }

    function test_debit() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        vm.stopPrank();

        // bankroll has 1_000_000
        assertEq(token.balanceOf(address(bankroll)), 1_000_000);
        assertEq(bankroll.liquidity(), 1_000_000);

        // investorOne has 1_000_000 shares
        assertEq(token.balanceOf(address(investorOne)), 0);
        assertEq(bankroll.sharesOf(address(investorOne)), 1_000_000);

        // pay player 500_000
        vm.prank(manager);
        bankroll.debit(player, 500_000);

        // bankroll now has 500_000
        assertEq(bankroll.liquidity(), 500_000);

        // player now has 500_000
        assertEq(token.balanceOf(address(player)), 500_000);

        // investorOne now has shares worth only 500_000
        assertEq(bankroll.getLpValue(address(investorOne)), 500_000);
    }

    function test_debitInsufficientFunds() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        assertEq(bankroll.liquidity(), 1000_000);

        vm.prank(manager);
        bankroll.debit(player, 5000_000);

        assertEq(bankroll.liquidity(), 0);
        assertEq(token.balanceOf(address(player)), 1000_000);
        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(bankroll.sharesOf(address(investorOne)), 1000_000);
        assertEq(bankroll.getLpValue(address(investorOne)), 0);
    }

    function test_credit() public {
        vm.startPrank(investorOne);
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
        vm.startPrank(investorOne);
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
        assertEq(bankroll.getLpValue(investorOne), 1006_500);

        vm.prank(investorOne);
        bankroll.withdrawAll();

        // investorOne should have claimed profit
        assertEq(bankroll.getInvestorStake(address(investorOne)), 0);
        assertEq(bankroll.getInvestorProfit(address(investorOne)), 0);
        assertEq(bankroll.getLpValue(address(investorOne)), 0);
    }

    // // function test_claimProfitWhenNegative() public {
    // // vm.startPrank(investorOne);
    // // token.approve(address(bankroll), 100_000);
    // // bankroll.depositFunds(100_000);
    // // vm.stopPrank();

    // // vm.prank(manager);
    // // bankroll.debit(player, 10_000);

    // // uint256 actualBalance = token.balanceOf(address(bankroll));
    // // uint256 availableBalance = bankroll.liquidity();
    // // int256 totalProfit = bankroll.totalProfit();

    // // // the actual balance is 90_000
    // // assertEq(actualBalance, 90_000);

    // // // the available balance should also be 90_000
    // // assertEq(availableBalance, 90_000);

    // // // profit is negative
    // // assertEq(totalProfit, -10_000);

    // // vm.prank(manager);
    // // vm.expectRevert(0xb5b9a8e6); //reverts: NO_PROFIT()
    // // bankroll.claimProfit();
    // // }

    // function test_setInvestorWhitelist() public {
    //     assertEq(bankroll.investorWhitelist(investorOne), false);

    //     vm.prank(admin);
    //     bankroll.setInvestorWhitelist(investorOne, true);

    //     assertEq(bankroll.investorWhitelist(investorOne), true);
    // }

    // function test_setAdmin() public {
    //     assertEq(bankroll.admin(), admin);

    //     vm.prank(admin);
    //     bankroll.setAdmin(investorOne);

    //     assertEq(bankroll.admin(), investorOne);
    // }

    // function test_setManager() public {
    //     assertEq(bankroll.managers(manager), true);

    //     vm.prank(admin);
    //     bankroll.setManager(investorOne, true);

    //     assertEq(bankroll.managers(investorOne), true);
    //     assertEq(bankroll.managers(manager), true);

    //     vm.prank(admin);
    //     bankroll.setManager(manager, false);

    //     assertEq(bankroll.managers(manager), false);
    // }

    // function test_setPublic() public {
    //     assertEq(bankroll.isPublic(), true);

    //     vm.prank(admin);
    //     bankroll.setPublic(false);

    //     assertEq(bankroll.isPublic(), false);
    // }

    // function test_setFee() public {
    //     assertEq(bankroll.fee(), 650);

    //     vm.prank(admin);
    //     bankroll.setFee(10);

    //     assertEq(bankroll.fee(), 10);
    // }

    // function test_getInvestorStake() public {
    //     vm.startPrank(investorOne);
    //     token.approve(address(bankroll), 10_000);
    //     bankroll.depositFunds(10_000);
    //     vm.stopPrank();

    //     vm.startPrank(investorTwo);
    //     token.approve(address(bankroll), 10_000);
    //     bankroll.depositFunds(10_000);
    //     vm.stopPrank();

    //     assertEq(bankroll.getInvestorStake(address(investorOne)), 5000);
    //     assertEq(bankroll.getInvestorStake(address(investorTwo)), 5000);

    //     vm.startPrank(investorOne);
    //     token.approve(address(bankroll), 10_000);
    //     bankroll.depositFunds(10_000);
    //     vm.stopPrank();

    //     assertEq(bankroll.getInvestorStake(address(investorOne)), 6666);
    //     assertEq(bankroll.getInvestorStake(address(investorTwo)), 3333);
    // }
}
