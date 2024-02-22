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

        dgBankrollManager.addOperator(operator);
        dgBankrollManager.approveBankroll(address(bankroll), lpFee);
    }

    function test_deployBankroll(address _operator, bytes32 _salt) public {
        dgBankrollFactory.deployBankroll(
            _operator, 
            address(token), 
            deGaming,
            maxRisk, 
            lpFee, 
            _salt
        );
    }

    function test_setBankrollImplementation(address _sender, address _bankroll) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.bankrollImpl() != _bankroll);

        dgBankrollFactory.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);
    
        vm.prank(_sender);
        dgBankrollFactory.setBankrollImplementation(_bankroll);

        assertEq(dgBankrollFactory.bankrollImpl(), _bankroll);
    }

    function test_setBankrollImplementation_incorrectRole(address _sender, address _bankroll) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) != true);

        vm.prank(_sender);
        vm.expectRevert();
        dgBankrollFactory.setBankrollImplementation(_bankroll);
    }

    function test_setDgBankrollManager(address _sender, address _bankrollManager) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.dgBankrollManager() != _bankrollManager);
       
        dgBankrollFactory.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);
    
        vm.prank(_sender);
        dgBankrollFactory.setDgBankrollManager(_bankrollManager);

        assertEq(dgBankrollFactory.dgBankrollManager(), _bankrollManager);
    }

    
    function test_setDgBankrollManager_incorrectRole(address _sender, address _bankrollManager) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) != true);

        vm.prank(_sender);
        vm.expectRevert();

        dgBankrollFactory.setDgBankrollManager(_bankrollManager);
    }

    function test_setDgAdmin(address _sender, address _admin) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.dgAdmin() != _admin);
        
        dgBankrollFactory.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);

        vm.prank(_sender);
        dgBankrollFactory.setDgAdmin(_admin);

        assertEq(dgBankrollFactory.dgAdmin(), _admin);
    }

    function test_setDgAdmin_incorrectRole(address _sender, address _admin) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) != true);

        vm.prank(_sender);
        vm.expectRevert();

        dgBankrollFactory.setDgAdmin(_admin);
    }
}