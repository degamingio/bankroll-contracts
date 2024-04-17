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


contract LPPov is Test {
    TransparentUpgradeableProxy public bankrollFactoryProxy;
    TransparentUpgradeableProxy public bankrollProxy;
    TransparentUpgradeableProxy public escrowProxy;
    TransparentUpgradeableProxy public bankrollManagerProxy;

    ProxyAdmin public proxyAdmin; 

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;

    address deGaming = address(0x0);

    // Addresses
    address public admin = address(0x1);
    address public deployer = address(0x2);
    address public operator = address(0x3);

    // player addresses:
    address player_0 = address(0x10);
    address player_1 = address(0x11);
    address player_2 = address(0x12);
    address player_3 = address(0x13);
    address player_4 = address(0x14);

    // LP addresses
    address LP_0 = address(0x20);
    address LP_1 = address(0x21);
    address LP_2 = address(0x22);
    address LP_3 = address(0x23);
    address LP_4 = address(0x24);

    uint256 LPsUSDTAmount = 10000e6;
    uint256 playerUSDTAmount = 10000e6;

    uint256 maxRisk = 8_000;
    uint256 threshold = 1000e6;

    MockToken token = new MockToken("Tether", "USDT");

    function setUp() public {
        vm.startPrank(deployer);

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

        bankroll = new Bankroll();

        bankrollFactoryProxy = new TransparentUpgradeableProxy(
            address(new DGBankrollFactory()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGBankrollFactory.initialize.selector,
                address(bankroll),
                address(dgBankrollManager),
                address(dgEscrow),
                admin,
                deGaming
            )
        );

        dgBankrollFactory = DGBankrollFactory(address(bankrollFactoryProxy));

        dgBankrollManager.grantRole(keccak256("ADMIN"), address(dgBankrollFactory));

        dgBankrollManager.grantRole(keccak256("ADMIN"), deployer);

        dgBankrollManager.grantRole(keccak256("ADMIN"), admin);

        dgEscrow.grantRole(keccak256("ADMIN"), admin);

        dgBankrollFactory.deployBankroll(address(token), maxRisk, threshold, "0x0");

        address bankrollAddress = dgBankrollFactory.bankrolls(dgBankrollFactory.bankrollCount() - 1);

        dgBankrollManager.addOperator(operator);

        dgBankrollManager.approveBankroll(bankrollAddress, 650);

        dgBankrollManager.setOperatorToBankroll(bankrollAddress, operator);

        bankroll = Bankroll(bankrollAddress);

        vm.stopPrank();

        vm.startPrank(admin);

        bankroll.maxContractsApprove();

        vm.stopPrank();

        token.mint(player_0, playerUSDTAmount);
        token.mint(player_1, playerUSDTAmount);
        token.mint(player_2, playerUSDTAmount);
        token.mint(player_3, playerUSDTAmount);
        token.mint(player_4, playerUSDTAmount);

        token.mint(LP_0, LPsUSDTAmount);
        token.mint(LP_1, LPsUSDTAmount);
        token.mint(LP_2, LPsUSDTAmount);
        token.mint(LP_3, LPsUSDTAmount);
        token.mint(LP_4, LPsUSDTAmount);

    }

    function test_PlayerPov() external view {
        console.log(bankroll.maxRiskPercentage());
    }
}