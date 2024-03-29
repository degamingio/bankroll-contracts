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
import {MockTokenUSDT} from "test/POC/MockTokenUSDT.sol";

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

    ProxyAdmin public proxyAdmin;

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;
    MockTokenUSDT public usdt;
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
        usdt = new MockTokenUSDT("usdt", "USDT");
        dgEscrow = new DGEscrow(1 weeks, address(dgBankrollManager));

        proxyAdmin = new ProxyAdmin();

        bankrollProxy = new TransparentUpgradeableProxy(
            address(new Bankroll()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Bankroll.initialize.selector,
                admin,
                address(usdt),
                address(dgBankrollManager),
                address(dgEscrow),
                owner,
                maxRisk,
                threshold
            )
        );

        bankroll = Bankroll(address(bankrollProxy));

        usdt.mint(address(bankroll), 1_000_000e6);

        dgBankrollManager.approveBankroll(address(bankroll), 0);

        vm.startPrank(admin);
        bankroll.maxContractsApprove();
        bankroll.changeEscrowThreshold(5_000);  
        vm.stopPrank();
    }


        function test_revertFunds_fail_USDT() public {
        vm.startPrank(address(bankroll));
        //We deposit 500,000 USDT to the escrow contract
        dgEscrow.depositFunds(player, operator, address(usdt), 500_000e6);
        vm.stopPrank();

        assertEq(usdt.balanceOf(address(dgEscrow)), 500_000e6);

        DGDataTypes.EscrowEntry memory entry = DGDataTypes.EscrowEntry(
            address(bankroll),
            operator,
            player,
            address(usdt),
            block.timestamp
        );

        bytes memory id = abi.encode(entry);
        //And then it will not work to revert the funds because we have already approved the escrow contract to spend the USDT
        vm.expectRevert();
       dgEscrow.revertFunds(id);
}

}