// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

/* OpenZeppelin contract */
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/* DeGaming Contracts */
import {Bankroll} from "src/Bankroll.sol";
import {DGBankrollManager} from "src/DGBankrollManager.sol";
import {DGEscrow} from "src/DGEscrow.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/* Mock Contracts */
import {MockToken} from "test/mock/MockToken.sol";

contract DGEscrowTest is Test {
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
        threshold = 10_000;

        proxyAdmin = new ProxyAdmin();

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

        token.mint(lpOne, 1_000_000e6);
        token.mint(lpTwo, 1_000_000e6);
        token.mint(admin, 1_000_000e6);

        dgBankrollManager.addOperator(operator);
        dgBankrollManager.approveBankroll(address(bankroll), 0);
        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);

        vm.startPrank(lpOne);
        token.approve(address(bankroll), 1_000_000e6);
        bankroll.depositFunds(1_000_000e6);
        vm.stopPrank();

        vm.startPrank(admin);

        bankroll.changeEscrowThreshold(5_000);

        bankroll.maxContractsApprove();
        vm.stopPrank();
    }

    function test_depositFundsEscrow() public {
        vm.startPrank(admin);
        token.approve(address(bankroll), 500e6);

        bankroll.debit(player, 500_001e6, operator);

        vm.stopPrank();

        assertEq(token.balanceOf(address(dgEscrow)), 500_001e6);
    }
    
    function test_revertFunds() public {
        vm.startPrank(admin);
        token.approve(address(bankroll), 500e6);

        bankroll.debit(player, 500_001e6, operator);

        vm.stopPrank();

        assertEq(token.balanceOf(address(dgEscrow)), 500_001e6);

        DGDataTypes.EscrowEntry memory entry = DGDataTypes.EscrowEntry(
            address(bankroll),
            operator,
            player,
            address(token),
            block.timestamp,
            0
        );

        bytes memory id = abi.encode(entry);

        dgEscrow.revertFunds(id);

        assertEq(token.balanceOf(address(dgEscrow)), 0);
    }

    function test_toggleLockEscrow() public {
        vm.startPrank(admin);
        token.approve(address(bankroll), 500e6);

        bankroll.debit(player, 500_001e6, operator);

        vm.stopPrank();

        assertEq(token.balanceOf(address(dgEscrow)), 500_001e6);

        DGDataTypes.EscrowEntry memory entry = DGDataTypes.EscrowEntry(
            address(bankroll),
            operator,
            player,
            address(token),
            block.timestamp,
            0
        );

        bytes memory id = abi.encode(entry);

        //dgEscrow.revertFunds(id);
        dgEscrow.toggleLockEscrow(id, true);

        vm.warp(1 weeks + 1);

        vm.startPrank(player);

        vm.expectRevert(DGErrors.ESCROW_LOCKED.selector);
        dgEscrow.claimUnaddressed(id);

        vm.stopPrank();
    }

    function test_releaseFunds() public {
        vm.startPrank(admin);
        token.approve(address(bankroll), 500e6);

        bankroll.debit(player, 500_001e6, operator);

        vm.stopPrank();

        assertEq(token.balanceOf(address(dgEscrow)), 500_001e6);

        DGDataTypes.EscrowEntry memory entry = DGDataTypes.EscrowEntry(
            address(bankroll),
            operator,
            player,
            address(token),
            block.timestamp,
            0
        );

        bytes memory id = abi.encode(entry);

        dgEscrow.releaseFunds(id);
        assertEq(token.balanceOf(address(player)), 500_001e6);
        assertEq(token.balanceOf(address(dgEscrow)), 0);
    }

    function test_claimUnaddressed(uint256 _time) public {
        vm.assume(_time < 10 hours);
        dgEscrow.setEventPeriod(_time);

        vm.startPrank(admin);
        token.approve(address(bankroll), 500e6);

        bankroll.debit(player, 500_001e6, operator);

        vm.stopPrank();

        DGDataTypes.EscrowEntry memory entry = DGDataTypes.EscrowEntry(
            address(bankroll),
            operator,
            player,
            address(token),
            block.timestamp,
            0
        );

        bytes memory id = abi.encode(entry);

        vm.warp(_time + 1);

        vm.prank(player);

        dgEscrow.claimUnaddressed(id);

        assertEq(token.balanceOf(player), 500_001e6);
    }

    function test_updateManager_escrow(address _faultyManager) external {
        vm.assume(!_isContract(_faultyManager));

        address oldManager = address(dgEscrow.dgBankrollManager());

        DGBankrollManager newManager = new DGBankrollManager();

        vm.expectRevert(DGErrors.ADDRESS_NOT_A_CONTRACT.selector);
        dgEscrow.updateBankrollManager(_faultyManager);

        dgEscrow.updateBankrollManager(address(newManager));

        assertNotEq(oldManager, address(newManager));
    }

    function _isContract(address _address) internal view returns (bool _isAddressContract) {
        uint256 size;

        assembly {
            size := extcodesize(_address)
        }

        _isAddressContract = size > 0;
    }
}
