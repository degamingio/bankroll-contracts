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

contract ESC_idCollission is Test {
    address admin;
    address operator;
    address lpOne;
    address lpTwo;
    address player;
    address owner;
    uint256 maxRisk;
    uint256 threshold;
    TransparentUpgradeableProxy public bankrollProxy;

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
        threshold = 10_000;

        dgBankrollFactory = new DGBankrollFactory();

        dgBankrollManager = new DGBankrollManager(admin);
        token = new MockToken("token", "MTK");

        dgEscrow = new DGEscrow(1 weeks, address(dgBankrollManager));

        proxyAdmin = new ProxyAdmin();

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

    function test_IdCollision() public {
        uint256 FIRST_AMOUNT = 500_001e6;
        uint256 SECOND_AMOUNT = 400_000e6;
        
        // Admin calls debit to player with FIRST_AMOUNT
        vm.prank(admin);
        bankroll.debit(player, FIRST_AMOUNT, operator);

        assertEq(token.balanceOf(address(dgEscrow)), FIRST_AMOUNT);
        console.log("balance of escrow", token.balanceOf(address(dgEscrow)));//500_002e6

        bytes memory id = _getId(player, operator, address(token)); 
        uint256 winnings = dgEscrow.escrowed(id);
        assertEq(winnings, FIRST_AMOUNT);

        // Admin calls debit to player with SECOND_AMOUNT within the same block
        vm.prank(admin);
        bankroll.debit(player, SECOND_AMOUNT, operator);

        // id and id2 are the same
        bytes memory id2 = _getId(player, operator, address(token));
        assertEq(id, id2);

        // winnings is updated to SECOND_AMOUNT
        winnings = dgEscrow.escrowed(id2);
        assertEq(winnings, SECOND_AMOUNT);

        // Release funds
        dgEscrow.releaseFunds(id);

        winnings = dgEscrow.escrowed(id);

        assertEq(winnings, 0);
        assertEq(token.balanceOf(address(player)), SECOND_AMOUNT);
        assertEq(token.balanceOf(address(dgEscrow)), FIRST_AMOUNT);
    }

    function _getId(address _player, address _operator, address _token) internal view returns (bytes memory _id) {
        DGDataTypes.EscrowEntry memory entry = DGDataTypes.EscrowEntry(
            address(bankroll),
            _operator,
            _player,
            address(_token),
            block.timestamp
        );

        _id = abi.encode(entry);
    }

}