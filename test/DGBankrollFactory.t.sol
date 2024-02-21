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
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/* Mock Contracts */
import {MockToken} from "test/mock/MockToken.sol";

contract DGBankrollFactoryTest is Test {
    address admin;
    address operator;
    address lp;
    address player;

    TransparentUpgradeableProxy public bankrollProxy;
    ProxyAdmin public proxyAdmin;

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    Bankroll public bankroll;
    MockToken public token;
    

    function setUp() public {
        admin = address(0x1);
        operator = address(0x2);
        lp = address(0x3);
        player = address(0x4);

        uint256 maxRisk = 10_000;

        dgBankrollFactory = new DGBankrollFactory();

        dgBankrollManager = new DGBankrollManager(admin, address(dgBankrollFactory));

        token = new MockToken("token", "MTK");

        proxyAdmin = new ProxyAdmin(msg.sender);

        bankrollProxy = new TransparentUpgradeableProxy(
            address(new Bankroll()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                Bankroll.initialize.selector,
                admin,
                address(token),
                address(dgBankrollManager),
                msg.sender,
                maxRisk
            )
        );

        bankroll = Bankroll(address(bankrollProxy));
    }
}