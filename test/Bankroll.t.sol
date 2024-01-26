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

        assertEq(bankroll.liquidity(), 2_000_000);
        assertEq(token.balanceOf(address(investorOne)), 0);
        assertEq(token.balanceOf(address(investorTwo)), 0);

        console.log(bankroll.lpProfit());
        emit log_int(bankroll.getExpectedInvestorProfit(investorOne));
        emit log_int(bankroll.getInvestorProfit(investorOne));

        vm.prank(investorOne);
        bankroll.withdrawAll();

        assertEq(bankroll.liquidity(), 1_000_000);

        console.log(token.balanceOf(address(investorOne)));
        // assertEq(token.balanceOf(address(investorOne)), 1000_000);
        assertEq(token.balanceOf(address(investorTwo)), 0);
    }

    function test_debit() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1_000_000);
        bankroll.depositFunds(1_000_000);
        vm.stopPrank();

        assertEq(token.balanceOf(address(bankroll)), 1_000_000);

        vm.prank(manager);
        bankroll.debit(player, 500_000);

        // assertEq(bankroll.liquidity(), 500_000);
        assertEq(token.balanceOf(address(player)), 500_000);

        console.log(token.balanceOf(address(player)));
        console.log(token.balanceOf(address(bankroll)));
        console.log(token.balanceOf(address(investorOne)));
        emit log_int(bankroll.expectedLiquidityProfit());


        assertEq(token.balanceOf(address(investorOne)), 0);

        assertEq(bankroll.sharesOf(address(investorOne)), 1_000_000);
        
        //assertEq(bankroll.getInvestorValue(address(investorOne)), 500_000);
    }

    // function test_debitInsufficientFunds() public {
        // vm.startPrank(investorOne);
        // token.approve(address(bankroll), 1000_000);
        // bankroll.depositFunds(1000_000);
        // vm.stopPrank();

        // assertEq(bankroll.liquidity(), 1000_000);

        // vm.prank(manager);
        // bankroll.debit(player, 5000_000);

        // assertEq(bankroll.liquidity(), 0);
        // assertEq(token.balanceOf(address(player)), 1000_000);
        // assertEq(token.balanceOf(address(investorOne)), 0);

        // assertEq(bankroll.sharesOf(address(investorOne)), 1000_000);
        // assertEq(bankroll.getInvestorValue(address(investorOne)), 0);
    // }

    function test_credit() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 1000_000);
        bankroll.depositFunds(1000_000);
        vm.stopPrank();

        vm.startPrank(manager);
        token.approve(address(bankroll), 500_000);
        bankroll.credit(500_000);
        vm.stopPrank();

        uint256 actualBalance = token.balanceOf(address(bankroll));
        uint256 availableProfit = bankroll.liquidity();
        int256 expectedProfit = bankroll.expectedLiquidityProfit();
        int256 currentProfit = bankroll.currentProfit();

        // the actual balance is 1500_000
        assertEq(actualBalance, 1500_000);

        // available balance + totalProfit = actual balance
        // assertEq(availableBalance + uint(currentProfit), actualBalance);

        // console.log(actualBalance);
        // console.log(availableProfit);
        // emit log_int(expectedProfit);
        // emit log_int(currentProfit);
        // emit log_int(bankroll.getInvestorProfit(investorOne));
        // emit log_int(bankroll.getExpectedInvestorProfit(investorOne));

        // available balance is 1500_000 - bankrollProfit
        //assertEq(bankroll.liquidity(), (1500_000 - uint(currentProfit)));
    }

    function test_claimProfit() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 100_000);
        bankroll.depositFunds(100_000);
        vm.stopPrank();

        vm.startPrank(manager);
        token.approve(address(bankroll), 10_000);
        bankroll.credit(10_000);
        vm.stopPrank();

        uint256 actualBalance = token.balanceOf(address(bankroll));
        uint256 expectedProfit = uint(bankroll.expectedLiquidityProfit());
        int256 currentProfit = bankroll.currentProfit();

        // the actual balance is 110_000
        assertEq(actualBalance, 110_000);
        console.log(actualBalance);

        // the available amount of profit for liquidity providers
        assertEq(expectedProfit, 650);
        console.log(expectedProfit);

        emit log_int(currentProfit);

        // // available balance + totalProfit = actual balance
        // assertEq(availableProfit + uint(currentProfit), actualBalance);

        uint256 fee = bankroll.fee();
        uint256 DENOMINATOR = bankroll.DENOMINATOR();
        uint256 bankrollProfit = (uint(currentProfit) * fee) / DENOMINATOR;

        console.log(bankrollProfit);

        vm.prank(manager);
        bankroll.claimProfit();

        uint256 availableProfit = bankroll.liquidity();
        console.log(availableProfit);

        console.log(bankroll.liquidity());

        // left in the bankroll as liquid assets is the initial investment
        assertEq(bankroll.liquidity(), 100650);

        // // left in the bankroll is the initial investment + brankroll fee
        // assertEq(token.balanceOf(address(bankroll)), 100_000 + bankrollProfit);

        // // total profit is is equal to the profit gained from fees
        // assertEq(bankroll.liquidity(), bankrollProfit);

        console.log(uint(bankroll.getInvestorValue(investorOne)));
        //console.log(uint(bankroll.getInvestorProfit(investorOne)));

        emit log_int(bankroll.getInvestorProfit(investorOne));


        // investor one has the initial investment + bankrollProfit
        assertEq(
            bankroll.getInvestorValue(address(investorOne)),
            100_000 + int(bankrollProfit)
        );
    }

    // function test_claimProfitWhenNegative() public {
        // vm.startPrank(investorOne);
        // token.approve(address(bankroll), 100_000);
        // bankroll.depositFunds(100_000);
        // vm.stopPrank();

        // vm.prank(manager);
        // bankroll.debit(player, 10_000);

        // uint256 actualBalance = token.balanceOf(address(bankroll));
        // uint256 availableBalance = bankroll.liquidity();
        // int256 totalProfit = bankroll.totalProfit();

        // // the actual balance is 90_000
        // assertEq(actualBalance, 90_000);

        // // the available balance should also be 90_000
        // assertEq(availableBalance, 90_000);

        // // profit is negative
        // assertEq(totalProfit, -10_000);

        // vm.prank(manager);
        // vm.expectRevert(0xb5b9a8e6); //reverts: NO_PROFIT()
        // bankroll.claimProfit();
    // }

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

    function test_setFee() public {
        assertEq(bankroll.fee(), 650);

        vm.prank(admin);
        bankroll.setFee(10);

        assertEq(bankroll.fee(), 10);
    }

    function test_getInvestorStake() public {
        vm.startPrank(investorOne);
        token.approve(address(bankroll), 10_000);
        bankroll.depositFunds(10_000);
        vm.stopPrank();

        vm.startPrank(investorTwo);
        token.approve(address(bankroll), 10_000);
        bankroll.depositFunds(10_000);
        vm.stopPrank();

        assertEq(bankroll.getInvestorStake(address(investorOne)), 5000);
        assertEq(bankroll.getInvestorStake(address(investorTwo)), 5000);

        vm.startPrank(investorOne);
        token.approve(address(bankroll), 10_000);
        bankroll.depositFunds(10_000);
        vm.stopPrank();

        assertEq(bankroll.getInvestorStake(address(investorOne)), 6666);
        assertEq(bankroll.getInvestorStake(address(investorTwo)), 3333);
    }
}
