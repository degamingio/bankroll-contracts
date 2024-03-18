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
        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);
        dgBankrollManager.approveBankroll(address(bankroll), 0);
    }

    // function test_depositFundsEscrow(address _player, address _operator, address _token, uint256 _winnings) external {
        // token.mint(address(bankroll), _winnings);
        // bankroll.maxContractsApprove();
        // vm.startPrank(address(bankroll));
        // dgEscrow.depositFunds(_player, _operator, _token, _winnings);
    // }
}
