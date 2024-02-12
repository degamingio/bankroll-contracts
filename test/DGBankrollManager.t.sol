// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// import "forge-std/Test.sol";

// import {Bankroll} from "src/Bankroll.sol";
// import {DGBankrollManager} from "src/DGBankrollManager.sol";

// import {DGErrors} from "src/libraries/DGErrors.sol";
// import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

// import {MockToken} from "test/mock/MockToken.sol";

// contract DGBankrollManagerTest is Test {
    // MockToken public mockToken;
    // DGBankrollManager public dgBankrollManager;

    // address public deGaming;
    // address public bankroll;
    // address public gameProvider;
    // address public manager;

    // uint64 public constant deGamingFee = 1_250;
    // uint64 public constant bankrollFee = 1_300;
    // uint64 public constant gameProviderFee = 650;
    // uint64 public constant managerFee = 6_800;

    // uint256 public constant DENOMINATOR = 10_000;

    // function setUp() public {
        // deGaming = vm.addr(2);
        // bankroll = vm.addr(3);
        // gameProvider = vm.addr(4);
        // manager = vm.addr(5);

        // vm.label(deGaming, "deGaming");
        // vm.label(bankroll, "bankroll");
        // vm.label(gameProvider, "gameProvider");
        // vm.label(manager, "manager");

        // mockToken = new MockToken("Mock USDC", "mUSDC");

        // dgBankrollManager = new DGBankrollManager();
    // }

    // function  test_setBankrollFees(address _bankrollAddress) public {
        // dgBankrollManager.setBankrollFees(address(_bankrollAddress), deGamingFee, bankrollFee, gameProviderFee, managerFee);

        // (uint256 _deGaming, uint256 _bankroll, uint256 _gameProvider, uint256 _manager) =
            // dgBankrollManager.bankrollFees(address(_bankrollAddress));

        // assertEq(_deGaming, deGamingFee);
        // assertEq(_bankroll, bankrollFee);
        // assertEq(_gameProvider, gameProviderFee);
        // assertEq(_manager, managerFee);
    // }
// }
