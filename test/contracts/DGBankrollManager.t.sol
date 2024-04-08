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

/* Mock Contracts */
import {MockToken} from "test/mock/MockToken.sol";

contract DGBankrollManagerTest is Test {
    MockToken public mockToken;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;
    DGBankrollFactory public dgBankrollFactory;
    
    TransparentUpgradeableProxy public escrowProxy;
    TransparentUpgradeableProxy public bankrollManagerProxy;
    TransparentUpgradeableProxy public bankrollFactoryProxy;
    TransparentUpgradeableProxy public bankrollProxy;

    ProxyAdmin public proxyAdmin;

    address admin;
    address deGaming;
    address operator;

    address[] operators;
    address[] lps;

    uint256 maxRisk = 10_000;
    uint256 threshold = 10_000;

    function setUp() public {
        admin = address(0x1);
        deGaming = address(0x2);
        operator = address(0x3);

        operators = [ 
            address(0x55), 
            address(0x56), 
            address(0x57),
            address(0x58),
            address(0x59),
            address(0x60)
        ];

        lps = [ 
            address(0x65), 
            address(0x66), 
            address(0x67),
            address(0x68),
            address(0x69),
            address(0x70)
        ];

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

        mockToken = new MockToken("Mock USDC", "mUSDC");

        //dgBankrollFactory = new DGBankrollFactory();

        //dgBankrollManager = new DGBankrollManager(deGaming);

        //dgEscrow = new DGEscrow(1 weeks, address(dgBankrollManager));

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
                address(mockToken),
                address(dgBankrollManager),
                address(dgEscrow),
                msg.sender,
                maxRisk,
                threshold
            )
        );

        bankroll = Bankroll(address(bankrollProxy));

        bankrollFactoryProxy = new TransparentUpgradeableProxy(
            address(dgBankrollFactory),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGBankrollFactory.initialize.selector,
                address(bankroll),
                address(dgBankrollManager),
                address(dgEscrow),
                deGaming,
                admin
            )
        );

        dgBankrollManager.grantRole(keccak256("ADMIN"), address(dgBankrollFactory));

        dgBankrollManager.grantRole(keccak256("ADMIN"), admin);

        vm.expectRevert(DGErrors.ADDRESS_NOT_A_CONTRACT.selector);
        dgBankrollManager.approveBankroll(admin, 650);
        
        dgBankrollManager.approveBankroll(address(bankroll), 650);

        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);

        mockToken.mint(admin, 1_000_000e6);

        vm.prank(admin);
    
        mockToken.approve(address(bankroll), 1_000_000e6);
    }

    function test_claimProfit() public {
        vm.startPrank(admin);
        bankroll.credit(1_000_000e6, operator);

        bankroll.maxContractsApprove();
        vm.stopPrank();

        dgBankrollManager.claimProfit(address(bankroll));
    }

    function test_claimProfit_nothingToClaim() public {
        vm.expectRevert(DGErrors.NOTHING_TO_CLAIM.selector);
        dgBankrollManager.claimProfit(address(bankroll));
    }

    function test_addOperator(address _operator) public {
        vm.assume(_operator != operator);
        vm.assume(!_isContract(_operator));

        vm.startPrank(admin);
        vm.expectRevert(DGErrors.NOT_AN_OPERATOR.selector);
        bankroll.credit(1_000_000e6, _operator);

        vm.expectRevert(DGErrors.ADDRESS_NOT_A_WALLET.selector);
        dgBankrollManager.addOperator(address(bankroll));

        dgBankrollManager.addOperator(_operator);

        vm.expectRevert(DGErrors.ADDRESS_NOT_A_WALLET.selector);
        dgBankrollManager.setOperatorToBankroll(address(bankroll), address(bankroll));

        dgBankrollManager.setOperatorToBankroll(address(bankroll), _operator);

        vm.expectRevert(DGErrors.OPERATOR_ALREADY_ADDED_TO_BANKROLL.selector);
        dgBankrollManager.setOperatorToBankroll(address(bankroll), _operator);


        //vm.prank(admin);
        bankroll.credit(1_000_000e6, _operator);

        assertEq(mockToken.balanceOf(address(bankroll)), 1_000_000e6);
        vm.stopPrank();
    }

    // function test_removeOperator(address _operator, address _operator2, address _operator3) public {
        // vm.assume(_operator != operator);
        // vm.assume(_operator2 != operator);
        // vm.assume(_operator3 != operator);
        // vm.assume(!_isContract(_operator));
        // vm.assume(!_isContract(_operator2));
        // vm.assume(!_isContract(_operator3));

        // vm.prank(admin);
        
        // vm.expectRevert(DGErrors.NOT_AN_OPERATOR.selector);
        // bankroll.credit(1_000_000e6, _operator);

        // dgBankrollManager.addOperator(_operator);
        // dgBankrollManager.setOperatorToBankroll(address(bankroll), _operator);
        // vm.prank(admin);
        // bankroll.credit(500_000e6, _operator);

        // assertEq(mockToken.balanceOf(address(bankroll)), 500_000e6);

        // dgBankrollManager.blockOperator(_operator);
        
        // vm.prank(admin);
        // vm.expectRevert(DGErrors.NOT_AN_OPERATOR.selector);
        // bankroll.credit(500_000e6, _operator);

        // dgBankrollManager.addOperator(_operator);
        // dgBankrollManager.removeOperatorFromBankroll(_operator, address(bankroll));

        // vm.prank(admin);
        // vm.expectRevert(DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL.selector);
        // bankroll.credit(500_000e6, _operator);

        // dgBankrollManager.addOperator(_operator);
        // dgBankrollManager.addOperator(_operator2);
        // dgBankrollManager.addOperator(_operator3);
        // dgBankrollManager.setOperatorToBankroll(address(bankroll), _operator);
        // dgBankrollManager.setOperatorToBankroll(address(bankroll), _operator2);
        // dgBankrollManager.setOperatorToBankroll(address(bankroll), _operator3);

        // vm.startPrank(admin);
        // bankroll.credit(1e6, _operator2);
        // bankroll.credit(1e6, _operator3);
        // vm.stopPrank();

        // dgBankrollManager.removeOperatorFromBankroll(_operator2, address(bankroll));

        // vm.prank(admin);
        // vm.expectRevert(DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL.selector);
        // bankroll.credit(1e6, _operator2);
    // }

    function test_updateFee(uint256 _newFee, uint256 _faultyFee, address _faultyBankroll, address _notAdmin) public {
        vm.assume(_newFee < 10_000);
        vm.assume(_faultyFee > 10_000);
        vm.assume(_faultyBankroll != address(bankroll));
        vm.assume(_notAdmin != address(dgBankrollFactory));
        vm.assume(_notAdmin != msg.sender);

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

    ///////////////////////////////////////////////////////////FIX
    function test_setDeGaming(address _newDegaming) public {
        vm.assume(_newDegaming != deGaming);
        // FIGURE OUT WHY THIS ISNT SET
        //assertEq(dgBankrollManager.deGaming(), deGaming);

        dgBankrollManager.setDeGaming(_newDegaming);
        assertEq(dgBankrollManager.deGaming(), _newDegaming);
    }

    function test_blockBankroll() public {
        vm.prank(admin);
        bankroll.credit(1_000_000e6, operator);

        dgBankrollManager.blockBankroll(address(bankroll));

        vm.expectRevert(DGErrors.BANKROLL_NOT_APPROVED.selector);
        dgBankrollManager.claimProfit(address(bankroll));
    }

    function test_feeOutOfRangeError(uint256 _fee, address _newBankroll) public {
        vm.assume(_fee > 10_000);

        vm.expectRevert(DGErrors.TO_HIGH_FEE.selector);
        dgBankrollManager.approveBankroll(_newBankroll, _fee);
    }

    // function test_feeIsCorrect(uint256 _wager) public {
        // vm.assume(_wager > 10_000e6);
        // vm.assume(_wager < 1_000_000e6);

        // mockToken.mint(admin, _wager * 5);

        // assertEq(mockToken.balanceOf(address(bankroll)), 0);

        // vm.prank(admin);
        // bankroll.credit(_wager, operator); 

        // assertEq(mockToken.balanceOf(address(bankroll)), _wager);

        // vm.startPrank(admin);
        // bankroll.maxContractsApprove();

        // dgBankrollManager.claimProfit(address(bankroll));
        // vm.stopPrank();

        // uint256 expectedBalance = (_wager * 650) / 10_000;

        // assertEq(mockToken.balanceOf(address(bankroll)), expectedBalance);

        // assertEq(mockToken.balanceOf(deGaming), _wager - expectedBalance);
    // }

    // function test_multipleOperators(uint256 _wager) public {
        // vm.assume(_wager < 150_000e6 && _wager > 500e6);

        // uint256 totalWagered; 
        // for (uint256 i = 0; i < operators.length; i++) {
            // dgBankrollManager.setOperatorToBankroll(address(bankroll), operators[i]);

            // vm.prank(admin);
            // bankroll.credit(_wager, operators[i]);
             
            // assertEq(mockToken.balanceOf(address(bankroll)), totalWagered + _wager);

            // totalWagered += _wager;
        // }

        // assertEq(totalWagered, _wager * operators.length);

        // uint256 expectedBalance = (totalWagered * 650) / 10_000;

        // vm.startPrank(admin);
        // bankroll.maxContractsApprove();

        // dgBankrollManager.claimProfit(address(bankroll));
        // vm.stopPrank();

        // assertApproxEqAbs(mockToken.balanceOf(address(bankroll)), expectedBalance, 5);

        // assertApproxEqAbs(mockToken.balanceOf(deGaming), totalWagered - expectedBalance, 5);
    // }

    function test_multipleLPs(uint256 _liquidity, uint256 _wager, uint256 _rand) public {
        vm.assume(_liquidity > 500e6 && _liquidity < 1_000_000_000e6);
        vm.assume(_wager < 1_000_000e6 && _wager > 500e6);

        uint256 rand = _rand % 5;

        for (uint256 i = 0; i < lps.length; i++) {
            vm.assume(lps[i] != address(0));
            mockToken.mint(lps[i], _liquidity);

            vm.startPrank(lps[i]);
            mockToken.approve(address(bankroll), _liquidity);
            bankroll.depositFunds(_liquidity);
            vm.stopPrank();
        }

        for (uint256 i = 0; i < lps.length; i++) {
            mockToken.mint(admin, _wager);
            vm.startPrank(admin);
            mockToken.approve(address(bankroll), _wager);
            bankroll.credit(_wager, operator);
            vm.stopPrank();
        }

        vm.prank(admin);
        bankroll.maxContractsApprove();

        assertEq(mockToken.balanceOf(address(bankroll)), (_wager + _liquidity) * lps.length);

        vm.prank(admin);
        dgBankrollManager.claimProfit(address(bankroll));

        uint256 expectedValue = _liquidity + (_wager * 650)/ 10_000;

        assertEq(expectedValue, bankroll.getLpValue(lps[rand]));
    }

    function test_updateEventPeriod(uint256 _newEventPeriod, address _wrongBankroll) public {
        assertEq(dgBankrollManager.eventPeriodOf(address(bankroll)), 30 days);

        vm.expectRevert(DGErrors.BANKROLL_NOT_APPROVED.selector);
        dgBankrollManager.updateEventPeriod(_wrongBankroll, _newEventPeriod);

        dgBankrollManager.updateEventPeriod(address(bankroll), _newEventPeriod);

        assertEq(dgBankrollManager.eventPeriodOf(address(bankroll)), _newEventPeriod);
    }

    /**
     * @notice
     *  Allows contract to check if the Token address actually is a contract
     *
     * @param _address address we want to  check
     *
     * @return _isAddressContract returns true if token is a contract, otherwise returns false
     *
     */
    function _isContract(address _address) internal view returns (bool _isAddressContract) {
        uint256 size;

        assembly {
            size := extcodesize(_address)
        }

        _isAddressContract = size > 0;
    }
}
