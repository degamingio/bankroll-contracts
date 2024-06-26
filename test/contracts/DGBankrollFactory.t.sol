// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

/* OpenZeppelin contract */
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

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

contract DGBankrollFactoryTest is Test {
    address admin;
    address owner;
    address operator;
    address deGaming;
    address lp;
    address player;
    uint256 maxRisk;
    uint256 threshold;
    uint256 lpFee;

    TransparentUpgradeableProxy public bankrollProxy;
    TransparentUpgradeableProxy public escrowProxy;
    TransparentUpgradeableProxy public bankrollManagerProxy;
    TransparentUpgradeableProxy public bankrollFactoryProxy;
    ProxyAdmin public proxyAdmin;

    DGBankrollFactory public dgBankrollFactory;
    DGBankrollManager public dgBankrollManager;
    DGEscrow public dgEscrow;
    Bankroll public bankroll;
    MockToken public token;
    
    bytes32 public constant DEFAULT_ADMIN_ROLE_HASH = 0x0;


    function setUp() public {
        admin = address(0x1);
        operator = address(0x2);
        lp = address(0x3);
        player = address(0x4);
        deGaming = address(0x5);
        owner = address(0x6);

        maxRisk = 10_000;
        threshold = 1_000_000e6;

        lpFee = 650;

        proxyAdmin = new ProxyAdmin();

        //dgBankrollFactory = new DGBankrollFactory();

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

        // bankroll = new Bankroll();

        // vm.startPrank(admin);

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
        // vm.stopPrank();

        dgBankrollManager.addOperator(operator);
    }

    function test_deployBankroll(address _operator, address _faultyToken, uint256 _faultyMaxRisk, bytes32 _salt) public {
        vm.assume(!_isContract(_operator));
        vm.assume(!_isContract(_faultyToken));
        vm.assume(_faultyMaxRisk > 10_000);

        vm.expectRevert(DGErrors.ADDRESS_NOT_A_CONTRACT.selector);
        dgBankrollFactory.deployBankroll(
            _faultyToken, 
            maxRisk,
            threshold, 
            _salt
        );

        vm.expectRevert(DGErrors.MAXRISK_TOO_HIGH.selector);
        dgBankrollFactory.deployBankroll(
            address(token), 
            _faultyMaxRisk,
            threshold,
            _salt
        );
        
        dgBankrollFactory.deployBankroll(
            address(token), 
            maxRisk,
            threshold, 
            _salt
        );

        dgBankrollManager.approveBankroll(
            dgBankrollFactory.bankrolls(0),
            lpFee
        );

        dgBankrollManager.setOperatorToBankroll(
            dgBankrollFactory.bankrolls(0),
            _operator
        );
    }

    function test_setBankrollImplementation(address _sender, address _faultyBankroll) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.bankrollImpl() != _faultyBankroll);
        vm.assume(!_isContract(_faultyBankroll));

        vm.prank(admin);
        dgBankrollFactory.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);
    
        vm.startPrank(_sender);
        vm.expectRevert(DGErrors.ADDRESS_NOT_A_CONTRACT.selector);
        dgBankrollFactory.setBankrollImplementation(_faultyBankroll);

        vm.stopPrank();

        Bankroll newBankroll = new Bankroll();

        vm.prank(_sender);
        dgBankrollFactory.setBankrollImplementation(address(newBankroll));

        assertEq(dgBankrollFactory.bankrollImpl(), address(newBankroll));
    }

    function test_setDeGaming(address _deGaming) public {
        dgBankrollFactory.setDeGaming(_deGaming);
        assertEq(dgBankrollFactory.deGaming(), _deGaming);
    }

    function test_setBankrollImplementation_incorrectRole(address _sender, address _bankroll) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.hasRole(DEFAULT_ADMIN_ROLE_HASH, _sender) != true);

        vm.prank(_sender);
        vm.expectRevert();
        dgBankrollFactory.setBankrollImplementation(_bankroll);
    }

    function test_setDgBankrollManager(address _sender, address _faultyBankrollManager) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.dgBankrollManager() != _faultyBankrollManager);
        vm.assume(!_isContract(_faultyBankrollManager));

        dgBankrollFactory.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);
    
        vm.startPrank(_sender);
        vm.expectRevert(DGErrors.ADDRESS_NOT_A_CONTRACT.selector);
        dgBankrollFactory.setDgBankrollManager(_faultyBankrollManager);
        vm.stopPrank();

        DGBankrollManager newBankrollManager = new DGBankrollManager();

        vm.prank(_sender);
        dgBankrollFactory.setDgBankrollManager(address(newBankrollManager));

        assertEq(dgBankrollFactory.dgBankrollManager(), address(newBankrollManager));
    }

    function test_setDgEscrow(address _sender, address _faultyEscrow) public {
        vm.assume(_sender != address(proxyAdmin));
        vm.assume(dgBankrollFactory.escrow() != _faultyEscrow);
        vm.assume(!_isContract(_faultyEscrow));

        dgBankrollFactory.grantRole(DEFAULT_ADMIN_ROLE_HASH, _sender);
    
        vm.startPrank(_sender);
        vm.expectRevert(DGErrors.ADDRESS_NOT_A_CONTRACT.selector);
        dgBankrollFactory.setDgEscrow(_faultyEscrow);
        vm.stopPrank();

        DGEscrow newEscrow = new DGEscrow();

        vm.prank(_sender);
        dgBankrollFactory.setDgEscrow(address(newEscrow));

        assertEq(dgBankrollFactory.escrow(), address(newEscrow));
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

    function test_predictBankrollAddress(bytes32 _salt) public {
        assertEq(
            dgBankrollFactory.predictBankrollAddress(_salt),
            Clones.predictDeterministicAddress(
                dgBankrollFactory.bankrollImpl(), 
                _salt, 
                address(dgBankrollFactory)
            )
        );
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