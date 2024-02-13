// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/* DeGaming Contracts */
import {Bankroll} from "src/Bankroll.sol";
import {DGBankrollManager} from "src/DGBankrollManager.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";

/* Mock Contracts */
import {MockToken} from "test/mock/MockToken.sol";

contract DGBankrollManagerTest is Test {
    MockToken public mockToken;
    DGBankrollManager public dgBankrollManager;
    Bankroll public bankroll;

    address admin;
    address deGaming;
    address operator;

    uint256 maxRisk = 10_000;

    function setUp() public {
        admin = address(0x1);
        deGaming = address(0x2);
        operator = address(0x3);

        mockToken = new MockToken("Mock USDC", "mUSDC");

        dgBankrollManager = new DGBankrollManager(deGaming);

        bankroll = new Bankroll(admin, address(mockToken), address(dgBankrollManager), maxRisk);

        dgBankrollManager.approveBankroll(address(bankroll));

        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);

    }

}
