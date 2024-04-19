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
    uint256 maxRisk;
    uint256 threshold;
    TransparentUpgradeableProxy public bankrollProxy;
    TransparentUpgradeableProxy public escrowProxy;
    TransparentUpgradeableProxy public bankrollManagerProxy;

    ProxyAdmin public proxyAdmin;

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;
    MockToken public token;

    function setUp() public {
        admin = address(0x1);
        operator = address(0x2);
        lpOne = address(0x3);
        lpTwo = address(0x4);
        player = address(0x5);
        owner = address(0x6);
        maxRisk = 10_000;
        threshold = 1_000_000e6;

        proxyAdmin = new ProxyAdmin();

        dgBankrollFactory = new DGBankrollFactory();

        bankrollManagerProxy = new TransparentUpgradeableProxy(
            address(new DGBankrollManager()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGBankrollManager.initialize.selector,
                admin
            )
        );

        dgBankrollManager = DGBankrollManager(address(bankrollManagerProxy));
        
        token = new MockToken("token", "MTK");

        escrowProxy = new TransparentUpgradeableProxy(
            address(new DGEscrow()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGEscrow.initialize.selector,
                1 weeks,
                address(dgBankrollManager)
            )
        );

        dgEscrow = DGEscrow(address(escrowProxy));

        bankrollProxy = new TransparentUpgradeableProxy(
            address(new Bankroll()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Bankroll.initialize.selector,
                admin,
                address(token),
                address(dgBankrollManager),
                address(dgEscrow),
                owner,
                maxRisk,
                threshold
            )
        );

        bankroll = Bankroll(address(bankrollProxy));

        vm.prank(admin);
        bankroll.maxContractsApprove();

        token.mint(lpOne, 1_000_000e6);
        token.mint(lpTwo, 1_000_000e6);
        token.mint(admin, 1_000_000e6);

        dgBankrollManager.addOperator(operator);
        dgBankrollManager.approveBankroll(address(bankroll), 0);
        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);
    }

    function test_calculateLiquidityPercentageAmount() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000e6);
        bankroll.depositFunds(1_000e6);
        assertEq(bankroll.calculateLiquidityPercentageAmount(5_000), 500e6);
        vm.stopPrank();
    }

    function test_setters() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000e6);
        bankroll.depositFunds(1_000e6);
        vm.stopPrank();
        assertEq(bankroll.withdrawableTimeOf(lpOne), block.timestamp + 1 weeks);
        vm.prank(admin);
        bankroll.setWithdrawableTimeOf(block.timestamp + 1 days, lpOne);
        assertEq(bankroll.withdrawableTimeOf(lpOne), block.timestamp + 1 days);
        assertEq(bankroll.minimumDepositionTime(), 1 weeks);
        vm.prank(admin);
        bankroll.setMinimumDepositionTime(2 days);
        assertEq(bankroll.minimumDepositionTime(), 2 days);
    }

    function test_predictShares() public {
        uint256 prediction = bankroll.previewMint(1_000e6);
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000e6);
        bankroll.depositFunds(1_000e6);
        vm.stopPrank();
        assertEq(bankroll.sharesOf(lpOne), prediction);
    }

    function test_depositFunds_() public {
        assertEq(bankroll.liquidity(), 0);

        // lp one deposits 1_000_000
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000e6);
        vm.stopPrank();

        assertEq(bankroll.totalSupply(), 1_000_000e6);
        assertEq(bankroll.liquidity(), 1_000_000e6);

        // lp two deposits 1_000_000
        vm.startPrank(lpTwo);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        assertEq(bankroll.sharesOf(address(lpTwo)), 1_000_000e6);
        vm.stopPrank();

        console.log(bankroll.sharesOf(address(lpTwo)));

        assertEq(bankroll.totalSupply(), 2_000_000e6);
        assertEq(bankroll.liquidity(), 2_000_000e6);
    }

    function test_depositFundsWithInvestorWhitelist() public {
        vm.prank(admin);
        bankroll.setPublic(DGDataTypes.LpIs.WHITELISTED);

        // lp one deposits 1_000_000
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        vm.expectRevert(DGErrors.LP_IS_NOT_WHITELISTED.selector); //reverts: FORBIDDEN()
        bankroll.depositFunds(1_000_000e6);
        vm.stopPrank();

        vm.prank(admin);
        bankroll.setInvestorWhitelist(lpOne, true);

        vm.startPrank(lpOne);
        bankroll.depositFunds(1_000_000e6);

        assertEq(bankroll.sharesOf(address(lpOne)), 1_000_000e6);

        vm.stopPrank();
    }

    function test_withdrawStageOne() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);

        vm.warp(block.timestamp + 1 weeks + 1);

        bankroll.withdrawalStageOne(bankroll.sharesOf(lpOne));

        vm.warp(block.timestamp + 3);

        // vm.expectRevert(DGErrors.WITHDRAWAL_PROCESS_IN_STAGING.selector);
        // bankroll.withdrawalStageOne(bankroll.sharesOf(lpOne));

        vm.stopPrank();
    }

    function test_updateBankrollManager(address _wallet) public {
        vm.assume(!_isContract(_wallet));
        DGBankrollManager newBankrollManager = new DGBankrollManager();

        vm.startPrank(admin);

        vm.expectRevert(DGErrors.ADDRESS_NOT_A_CONTRACT.selector);
        bankroll.updateBankrollManager(_wallet);

        bankroll.updateBankrollManager(address(newBankrollManager));

        bankroll.maxContractsApprove();

        vm.stopPrank();
        assertEq(token.allowance(address(bankroll), address(newBankrollManager)), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    function test_withdrawStageTwo() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        
        vm.warp(block.timestamp + 1 weeks + 1);

        bankroll.withdrawalStageOne(bankroll.sharesOf(lpOne));

        vm.warp(block.timestamp + 30);

        bankroll.withdrawalStageTwo();

        vm.stopPrank();
    }

    function test_setWithdrawalEventPeriod(uint256 _newEventPeriod) public{
        vm.assume(_newEventPeriod < 45 minutes);
        vm.assume(_newEventPeriod > 30 minutes);
        vm.prank(admin);
        bankroll.setWithdrawalEventPeriod(_newEventPeriod);

        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        
        vm.warp(block.timestamp + 1 weeks + 1);

        bankroll.withdrawalStageOne((bankroll.sharesOf(lpOne)) / 2);

        vm.warp(block.timestamp + _newEventPeriod + 1);

        bankroll.withdrawalStageOne((bankroll.sharesOf(lpOne)) / 2);

        vm.stopPrank();
    }

    function test_setWithdrawalDelay(uint256 _newWithdrawalDelay) public {
        vm.assume(_newWithdrawalDelay > 31);
        vm.assume(_newWithdrawalDelay < 300);
        
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        
        vm.warp(block.timestamp + 1 weeks + 1);

        bankroll.withdrawalStageOne(bankroll.sharesOf(lpOne));
        vm.stopPrank();

        vm.prank(admin);
        bankroll.setWithdrawalDelay(_newWithdrawalDelay);

        vm.startPrank(lpOne);
        vm.warp(3);

        vm.expectRevert(DGErrors.OUTSIDE_WITHDRAWAL_WINDOW.selector);
        bankroll.withdrawalStageTwo();

        vm.stopPrank();
    }

    function test_setWithdrawalWindow() public {
        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        
        vm.warp(block.timestamp + 1 weeks + 1);

        bankroll.withdrawalStageOne(bankroll.sharesOf(lpOne));
        vm.stopPrank();

        vm.prank(admin);
        bankroll.setWithdrawalWindow(30);

        vm.startPrank(lpOne);
        vm.warp(61);

        vm.expectRevert(DGErrors.OUTSIDE_WITHDRAWAL_WINDOW.selector);
        bankroll.withdrawalStageTwo();

        vm.stopPrank();
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

        // Test operator revert
        dgBankrollManager.addOperator(address(69));
        vm.prank(admin);
        vm.expectRevert(DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL.selector);
        bankroll.debit(player, 500_000e6, address(69));

        // pay player 500_000
        vm.startPrank(admin);
        bankroll.debit(player, 500_000e6, operator);
        vm.stopPrank();

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

        // Test operator revert
        dgBankrollManager.addOperator(address(69));
        vm.startPrank(admin);
        token.approve(address(bankroll), 500_000e6);
        vm.expectRevert(DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL.selector);
        bankroll.credit(500_000e6, address(69));
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

    function test_changeMaxRisk(uint256 _faultyMaxRisk, uint256 _correctMaxRisk) public {
        vm.assume(_faultyMaxRisk > 10_000);
        vm.assume(_correctMaxRisk < 10_000);

        vm.startPrank(admin);

        vm.expectRevert(DGErrors.MAXRISK_TOO_HIGH.selector);
        bankroll.changeMaxRisk(_faultyMaxRisk);

        bankroll.changeMaxRisk(_correctMaxRisk);
        vm.stopPrank();
    }

    function test_setInvestorWhitelist() public {
        assertEq(bankroll.lpWhitelist(lpOne), false);

        vm.expectRevert(DGErrors.NO_LP_ACCESS_PERMISSION.selector);
        bankroll.setInvestorWhitelist(lpOne, true);

        vm.prank(admin);
        bankroll.setInvestorWhitelist(lpOne, true);

        assertEq(bankroll.lpWhitelist(lpOne), true);
    }

    function test_setPublic() public {
        assertEq(uint256(bankroll.lpIs()), 0);

        vm.prank(admin);
        bankroll.setPublic(DGDataTypes.LpIs.WHITELISTED);

        assertEq(uint256(bankroll.lpIs()), 1);
    }

    function test_getLpStake(address _lp) public {
        assertEq(bankroll.getLpStake(_lp), 0);
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
    }

    function test_getLPValue(address _lp) public {
        assertEq(bankroll.getLpValue(_lp), 0);
    }

    function test_printErrors() public view {
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
        console.logBytes4(DGErrors.MAXRISK_TOO_HIGH.selector);

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
