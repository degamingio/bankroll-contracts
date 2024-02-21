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
    address deGaming;
    address lp;
    address player;
    uint256 maxRisk;
    uint256 lpFee;

    TransparentUpgradeableProxy public bankrollFactoryProxy;
    ProxyAdmin public proxyAdmin;

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    Bankroll public bankroll;
    MockToken public token;
    
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0;


    function setUp() public {
        admin = address(0x1);
        operator = address(0x2);
        lp = address(0x3);
        player = address(0x4);
        deGaming = address(0x5);

        maxRisk = 10_000;

        lpFee = 650;

        //dgBankrollFactory = new DGBankrollFactory();

        dgBankrollManager = new DGBankrollManager(admin, address(dgBankrollFactory));

        token = new MockToken("token", "MTK");

        proxyAdmin = new ProxyAdmin(msg.sender);

        bankroll = new Bankroll();
   
        bankrollFactoryProxy = new TransparentUpgradeableProxy(
            address(new DGBankrollFactory()),
            address(proxyAdmin),
            abi.encodeWithSelector(
                DGBankrollFactory.initialize.selector,
                address(bankroll),
                address(dgBankrollManager),
                admin
            )
        );

        dgBankrollFactory = DGBankrollFactory(address(bankrollFactoryProxy));

        //bankroll = Bankroll(address(bankrollProxy));

        dgBankrollManager.addOperator(operator);
        dgBankrollManager.approveBankroll(address(bankroll), lpFee);
    }

    function test_deployBankroll(address _operator, bytes32 _salt) public {
        // vm.assume(_operator != address(0));
        dgBankrollFactory.deployBankroll(
            _operator, 
            address(token), 
            deGaming,
            maxRisk, 
            lpFee, 
            _salt
        );
    }
}