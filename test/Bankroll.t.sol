// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import "forge-std/Test.sol";

// /* DeGaming Contracts */
// import {Bankroll} from "src/Bankroll.sol";
// import {DGBankrollManager} from "src/DGBankrollManager.sol";

// /* DeGaming Libraries */
// import {DGErrors} from "src/libraries/DGErrors.sol";
// import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

// /* Mock Contracts */
// import {MockToken} from "test/mock/MockToken.sol";


// contract BankrollTest is Test {
    // address admin;
    // address operator;
    // address lpOne;
    // address lpTwo;
    // address player;
    // address bankrollManager;

    // DGBankrollManager dgBankrollManager;
    // Bankroll bankroll;
    // MockToken token;

    // function setUp() public {
        // admin = address(0x1);
        // operator = address(0x2);
        // lpOne = address(0x3);
        // lpTwo = address(0x4);
        // player = address(0x5);
        // //bankrollManager = address(0x6);
        // uint256 maxRisk = 10_000;
        
        // dgBankrollManager = new DGBankrollManager(admin);
        // token = new MockToken("token", "MTK");
        // bankroll = new Bankroll(admin, address(token), address(dgBankrollManager), maxRisk);

        // token.mint(lpOne, 1_000_000);
        // token.mint(lpTwo, 1_000_000);
        // token.mint(admin, 1_000_000);

        // dgBankrollManager.addOperator(operator);
        // dgBankrollManager.approveBankroll(address(bankroll), 0);
    // }

    // function test_depositFunds() public {
        // assertEq(bankroll.liquidity(), 0);

        // // lp one deposits 1000_000
        // vm.startPrank(lpOne);
        // token.approve(address(bankroll), 1_000_000);
        // bankroll.depositFunds(1_000_000);
        // assertEq(bankroll.depositOf(address(lpOne)), 1_000_000);
        // assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000);
        // vm.stopPrank();

        // assertEq(bankroll.totalSupply(), 1_000_000);
        // assertEq(bankroll.liquidity(), 1_000_000);

        // // lp two deposits 1000_000
        // vm.startPrank(lpTwo);
        // token.approve(address(bankroll), 1_000_000);
        // bankroll.depositFunds(1_000_000);
        // assertEq(bankroll.depositOf(address(lpTwo)), 1_000_000);
        // assertEq(bankroll.sharesOf(address(lpTwo)), 1_000_000);
        // vm.stopPrank();

        // assertEq(bankroll.totalSupply(), 2_000_000);
        // assertEq(bankroll.liquidity(), 2_000_000);
    // }

    // function test_depositFundsWithInvestorWhitelist() public {
        // vm.prank(admin);
        // bankroll.setPublic(DGDataTypes.LpIs.WHITELISTED);

        // // lp one deposits 1000_000
        // vm.startPrank(lpOne);
        // token.approve(address(bankroll), 1_000_000);
        // vm.expectRevert(DGErrors.LP_IS_NOT_WHITELISTED.selector); //reverts: FORBIDDEN()
        // bankroll.depositFunds(1_000_000);
        // vm.stopPrank();

        // vm.prank(admin);
        // bankroll.setInvestorWhitelist(lpOne, true);

        // vm.startPrank(lpOne);
        // bankroll.depositFunds(1_000_000);

        // assertEq(bankroll.depositOf(address(lpOne)), 1_000_000);
        // assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000);

        // vm.stopPrank();
    // }

    // function test_withdrawAll() public {
        // vm.startPrank(lpOne);
        // token.approve(address(bankroll), 1_000_000);
        // bankroll.depositFunds(1_000_000);
        // vm.stopPrank();

        // vm.startPrank(lpTwo);
        // token.approve(address(bankroll), 1_000_000);
        // bankroll.depositFunds(1_000_000);
        // vm.stopPrank();

        // // funds have been deposited
        // assertEq(bankroll.liquidity(), 2_000_000);
        // assertEq(token.balanceOf(address(lpOne)), 0);
        // assertEq(token.balanceOf(address(lpTwo)), 0);

        // // initial deposit
        // assertEq(bankroll.depositOf(address(lpOne)), 1_000_000);
        // assertEq(bankroll.depositOf(address(lpTwo)), 1_000_000);

        // // zero in profits because no fees have been collected
        // assertEq(bankroll.getLpProfit(address(lpOne)), 0);
        // assertEq(bankroll.getLpProfit(address(lpTwo)), 0);

        // vm.startPrank(lpOne);
        // bankroll.withdrawAll();
        // vm.stopPrank();

        // // funds have been deposited
        // assertEq(bankroll.liquidity(), 1_000_000);
        // assertEq(token.balanceOf(address(lpOne)), 1_000_000);
        // assertEq(token.balanceOf(address(lpTwo)), 0);
    // }

    // function test_debit() public {
        // vm.startPrank(lpOne);
        // token.approve(address(bankroll), 1_000_000);
        // bankroll.depositFunds(1_000_000);
        // vm.stopPrank();

        // // bankroll has 1_000_000
        // assertEq(token.balanceOf(address(bankroll)), 1_000_000);
        // assertEq(bankroll.liquidity(), 1_000_000);

        // // lpOne has 1_000_000 shares
        // assertEq(token.balanceOf(address(lpOne)), 0);
        // assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000);

        // // pay player 500_000
        // vm.prank(admin);
        // bankroll.debit(player, 500_000, address(operator));

        // // bankroll now has 500_000
        // assertEq(bankroll.liquidity(), 500_000);

        // // player now has 500_000
        // assertEq(token.balanceOf(address(player)), 500_000);

        // // lpOne now has shares worth only 500_000
        // assertEq(bankroll.getLpValue(address(lpOne)), 500_000);
    // }

    // function test_debitInsufficientFunds() public {
        // vm.startPrank(lpOne);
        // token.approve(address(bankroll), 1_000_000);
        // bankroll.depositFunds(1_000_000);
        // vm.stopPrank();

        // assertEq(bankroll.liquidity(), 1_000_000);

        // vm.prank(admin);
        // bankroll.debit(player, 5000_000, address(operator));

        // assertEq(bankroll.liquidity(), 0);
        // assertEq(token.balanceOf(address(player)), 1_000_000);
        // assertEq(token.balanceOf(address(lpOne)), 0);

        // assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000);
        // assertEq(bankroll.getLpValue(address(lpOne)), 0);
    // }

    // function test_credit() public {
        // vm.startPrank(lpOne);
        // token.approve(address(bankroll), 1_000_000);
        // bankroll.depositFunds(1_000_000);
        // vm.stopPrank();

        // vm.startPrank(admin);
        // token.approve(address(bankroll), 500_000);
        // bankroll.credit(500_000, address(operator));
        // vm.stopPrank();

        // // profit is not available for LPs before managers has claimed it
        // assertEq(bankroll.liquidity(), 1_000_000);
        // assertEq(bankroll.GGR(), 500_000);
        // assertEq(bankroll.lpsProfit(), 0);
    // }

    // function test_setInvestorWhitelist() public {
        // assertEq(bankroll.lpWhitelist(lpOne), false);

        // vm.prank(admin);
        // bankroll.setInvestorWhitelist(lpOne, true);

        // assertEq(bankroll.lpWhitelist(lpOne), true);
    // }

    // function test_updateAdmin(address _newAdmin) public {
        // token.mint(_newAdmin, 10);

        // vm.prank(_newAdmin);
        // token.approve(address(bankroll), 10);
        // vm.expectRevert();
        // bankroll.credit(10, operator);
        // vm.stopPrank(); 
     
        // bankroll.updateAdmin(admin, _newAdmin);
        // vm.startPrank(_newAdmin);
        // token.approve(address(bankroll), 10);
        // bankroll.credit(10, operator);
        // vm.stopPrank();
    // }

    // function test_setPublic() public {
        // assertEq(uint256(bankroll.lpIs()), 0);

        // vm.prank(admin);
        // bankroll.setPublic(DGDataTypes.LpIs.WHITELISTED);

        // assertEq(uint256(bankroll.lpIs()), 1);
    // }

    // function test_getLpStake() public {
        // vm.startPrank(lpOne);
        // token.approve(address(bankroll), 10_000);
        // bankroll.depositFunds(10_000);
        // vm.stopPrank();

        // vm.startPrank(lpTwo);
        // token.approve(address(bankroll), 10_000);
        // bankroll.depositFunds(10_000);
        // vm.stopPrank();

        // assertEq(bankroll.getLpStake(address(lpOne)), 5000);
        // assertEq(bankroll.getLpStake(address(lpTwo)), 5000);

        // vm.startPrank(lpOne);
        // token.approve(address(bankroll), 10_000);
        // bankroll.depositFunds(10_000);
        // vm.stopPrank();

        // assertEq(bankroll.getLpStake(address(lpOne)), 6666);
        // assertEq(bankroll.getLpStake(address(lpTwo)), 3333);
    // }
// }
