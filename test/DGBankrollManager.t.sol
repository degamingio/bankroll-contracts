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

/* Mock Contracts */
import {MockToken} from "test/mock/MockToken.sol";

contract DGBankrollManagerTest is Test {
    MockToken public mockToken;
    DGBankrollManager public dgBankrollManager;
    Bankroll public bankroll;
    DGBankrollFactory public dgBankrollFactory;
    TransparentUpgradeableProxy public bankrollProxy;

    ProxyAdmin public proxyAdmin;

    address admin;
    address deGaming;
    address operator;

    uint256 maxRisk = 10_000;

    function setUp() public {
        admin = address(0x1);
        deGaming = address(0x2);
        operator = address(0x3);

        mockToken = new MockToken("Mock USDC", "mUSDC");

        dgBankrollFactory = new DGBankrollFactory();

        dgBankrollManager = new DGBankrollManager(deGaming, address(dgBankrollFactory));

        proxyAdmin = new ProxyAdmin(msg.sender);

        bankrollProxy = new TransparentUpgradeableProxy(
            address(new Bankroll()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Bankroll.initialize.selector,
                admin,
                address(mockToken),
                address(dgBankrollManager),
                msg.sender,
                maxRisk
            )
        );

        bankroll = Bankroll(address(bankrollProxy));

        dgBankrollManager.approveBankroll(address(bankroll), 650);

        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);

        mockToken.mint(admin, 1_000_000);

        vm.prank(admin);
    
        mockToken.approve(address(bankroll), 1_000_000);
    }

    function test_tokenAddress() public{
        assertEq(bankroll.viewTokenAddress(), address(mockToken));
    }

    function test_claimProfit() public {    
        vm.prank(admin);
        bankroll.credit(1_000_000, operator);

        bankroll.maxBankrollManagerApprove();

        dgBankrollManager.claimProfit(address(bankroll));
    }

    function test_claimProfit_nothingToClaim() public {
        vm.expectRevert(DGErrors.NOTHING_TO_CLAIM.selector);
        dgBankrollManager.claimProfit(address(bankroll));
    }

    function test_addOperator(address _operator) public {
        vm.prank(admin);
        vm.expectRevert(DGErrors.NOT_AN_OPERATOR.selector);
        bankroll.credit(1_000_000, _operator);

        dgBankrollManager.addOperator(_operator);
        vm.prank(admin);
        bankroll.credit(1_000_000, _operator);

        assertEq(mockToken.balanceOf(address(bankroll)), 1_000_000);
    }

    function test_removeOperator(address _operator) public {
        vm.prank(admin);
        vm.expectRevert(DGErrors.NOT_AN_OPERATOR.selector);
        bankroll.credit(1_000_000, _operator);

        dgBankrollManager.addOperator(_operator);
        vm.prank(admin);
        bankroll.credit(500_000, _operator);

        assertEq(mockToken.balanceOf(address(bankroll)), 500_000);

        dgBankrollManager.blockOperator(_operator);
        
        vm.prank(admin);
        vm.expectRevert(DGErrors.NOT_AN_OPERATOR.selector);
        bankroll.credit(500_000, _operator);
    }

    function test_updateFee(uint256 _newFee, uint256 _faultyFee, address _faultyBankroll, address _notAdmin) public {
        vm.assume(_newFee < 10_000);
        vm.assume(_faultyFee > 10_000);


        vm.expectRevert();
        vm.prank(_notAdmin);
        dgBankrollManager.updateLpFee(address(bankroll), _newFee);

        vm.expectRevert(DGErrors.BANKROLL_NOT_APPROVED.selector);
        dgBankrollManager.updateLpFee(_faultyBankroll, _newFee);

        vm.expectRevert(DGErrors.TO_HIGH_FEE.selector);
        dgBankrollManager.updateLpFee(address(bankroll), _faultyFee);

        dgBankrollManager.updateLpFee(address(bankroll), _newFee);

        assertEq(dgBankrollManager.lpFeeOf(address(bankroll)), _newFee);
    }

    function test_blockBankroll() public {
        vm.prank(admin);
        bankroll.credit(1_000_000, operator);

        dgBankrollManager.blockBankroll(address(bankroll));

        vm.expectRevert(DGErrors.BANKROLL_NOT_APPROVED.selector);
        dgBankrollManager.claimProfit(address(bankroll));
    }

    function test_feeOutOfRangeError(uint256 _fee, address _newBankroll) public {
        vm.assume(_fee > 10_000);

        vm.expectRevert(DGErrors.TO_HIGH_FEE.selector);
        dgBankrollManager.approveBankroll(_newBankroll, _fee);
    }

    function test_updateAdmin(address _newAdmin, address _newOperator) public {
        vm.assume(_newAdmin != admin);
        vm.assume(_newOperator != operator);

        vm.prank(_newAdmin);
        vm.expectRevert();
        dgBankrollManager.addOperator(_newOperator);

        vm.prank(admin);
        vm.expectRevert(DGErrors.NOT_AN_OPERATOR.selector);
        bankroll.debit(address(0x4), 10, _newOperator);

        dgBankrollManager.updateAdmin(admin, _newAdmin);
        vm.prank(_newAdmin);
        dgBankrollManager.addOperator(_newOperator);

        vm.prank(admin);
        bankroll.debit(address(0x4), 10, _newOperator);
    }

    function test_feeIsCorrect(uint256 _wager) public {
        vm.assume(_wager > 10_000);
        vm.assume(_wager < 1_000_000);

        mockToken.mint(admin, _wager * 5);

        assertEq(mockToken.balanceOf(address(bankroll)), 0);

        vm.prank(admin);
        bankroll.credit(_wager, operator); 

        assertEq(mockToken.balanceOf(address(bankroll)), _wager);

        bankroll.maxBankrollManagerApprove();
        
        dgBankrollManager.claimProfit(address(bankroll));

        uint256 expectedBalance = (_wager * 650) / 10_000;

        assertEq(mockToken.balanceOf(address(bankroll)), expectedBalance);

        assertEq(mockToken.balanceOf(deGaming), _wager - expectedBalance);
    }

    function test_multipleOperators(address[5] memory _operators, uint256 _wager) public {
        vm.assume(_operators.length == 5);
        vm.assume(_wager < 200_000 && _wager > 500);

        uint256 totalWagered; 
        for (uint256 i = 0; i < _operators.length; i++) {
            dgBankrollManager.setOperatorToBankroll(address(bankroll), _operators[i]);

            vm.prank(admin);
            bankroll.credit(_wager, _operators[i]);
             
            assertEq(mockToken.balanceOf(address(bankroll)), totalWagered + _wager);

            totalWagered += _wager;
        }

        assertEq(totalWagered, _wager * _operators.length);

        uint256 expectedBalance = (totalWagered * 650) / 10_000;

        bankroll.maxBankrollManagerApprove();

        dgBankrollManager.claimProfit(address(bankroll));

        assertApproxEqAbs(mockToken.balanceOf(address(bankroll)), expectedBalance, 5);

        assertApproxEqAbs(mockToken.balanceOf(deGaming), totalWagered - expectedBalance, 5);
    }

    function test_multipleLPs(address[5] memory _lps, uint256 _liquidity, uint256 _wager, uint256 _rand) public {
        vm.assume(_lps.length == 5);
        vm.assume(_liquidity > 500 && _liquidity < 1_000_000_000);
        vm.assume(_wager < 1_000_000 && _wager > 500);

        uint256 rand = _rand % 5;

        for (uint256 i = 0; i < _lps.length; i++) {
            vm.assume(_lps[i] != address(0));
            mockToken.mint(_lps[i], _liquidity);

            vm.startPrank(_lps[i]);
            mockToken.approve(address(bankroll), _liquidity);
            bankroll.depositFunds(_liquidity);
            vm.stopPrank();
        }

        for (uint256 i = 0; i < _lps.length; i++) {
            mockToken.mint(admin, _wager);
            vm.startPrank(admin);
            mockToken.approve(address(bankroll), _wager);
            bankroll.credit(_wager, operator);
            vm.stopPrank();
        }

        bankroll.maxBankrollManagerApprove();

        assertEq(mockToken.balanceOf(address(bankroll)), (_wager + _liquidity) * _lps.length);

        dgBankrollManager.claimProfit(address(bankroll));

        uint256 expectedValue = _liquidity + (_wager * 650)/ 10_000;

        assertApproxEqAbs(expectedValue, bankroll.getLpValue(_lps[rand]), 5);

    }
}
