// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../lib/properties/contracts/util/Hevm.sol";

/* OpenZeppelin contract */
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/* DeGaming Contracts */
import {Bankroll} from "src/Bankroll.sol";
import {DGBankrollManager} from "src/DGBankrollManager.sol";
import {DGBankrollFactory} from "src/DGBankrollFactory.sol";
import {DGEscrow} from "src/DGEscrow.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";

/* Mock Contracts */
import {MockToken} from "test/mock/MockToken.sol";

abstract contract Setup {
    //DGBankroll.sol
    uint256 sumOfShares;
    int256 sumOfGgr;

    //DGBankrollManager.sol

    //DGEscrow.sol

    MockToken mockToken;
    DGBankrollManager dgBankrollManager;
    DGEscrow dgEscrow;
    Bankroll bankroll;
    DGBankrollFactory dgBankrollFactory;
    TransparentUpgradeableProxy bankrollProxy;

    ProxyAdmin proxyAdmin;

    address admin;
    address deGaming;
    address operator;
    address player;

    address[] operators;
    address[] lps;

    uint256 maxRisk = 10_000;
    uint256 threshold = 10_000;

    function setup() internal {
        admin = address(0x11);
        deGaming = address(0x22);
        operator = address(0x33);
        player = address(0x44);

        mockToken = new MockToken("Mock USDC", "mUSDC");

        dgBankrollFactory = new DGBankrollFactory();

        dgBankrollManager = new DGBankrollManager(deGaming);

        dgEscrow = new DGEscrow(1 weeks, address(dgBankrollManager));

        proxyAdmin = new ProxyAdmin();

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

        dgBankrollManager.grantRole(keccak256("ADMIN"), address(dgBankrollFactory));

        dgBankrollManager.grantRole(keccak256("ADMIN"), admin);

        dgBankrollManager.approveBankroll(address(bankroll), 650);

        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);
    }

    function _initMint(address user, uint256 amount) internal {
        mockToken.mint(user, amount);
    }

    function _getSharesToAmount(uint256 _shares) internal view returns (uint256 amount) {
        if (bankroll.liquidity() == 0) {
            amount = _shares;
        } else {
            amount = (_shares * bankroll.liquidity()) / bankroll.totalSupply();
        }
    }

    function _getAmountToShares(uint256 _amount) internal view returns (uint256 shares) {
        if (bankroll.liquidity() == 0) {
            shares = _amount;
        } else {
            shares = (_amount * bankroll.totalSupply()) / bankroll.liquidity();
        }
    }
}
