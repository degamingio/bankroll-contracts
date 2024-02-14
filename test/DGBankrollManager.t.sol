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

        dgBankrollManager.approveBankroll(address(bankroll), 650);

        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);

        mockToken.mint(admin, 1_000_000);

        vm.prank(admin);
    
        mockToken.approve(address(bankroll), 1_000_000);
    }

    function test_claimProfit() public {    
        vm.prank(admin);
        bankroll.credit(1_000_000, operator);

        bankroll.maxBankrollManagerApprove();

        dgBankrollManager.claimProfit(address(bankroll));
    }

    function test_claimProfit_nothingToClaim() public {
        vm.expectRevert(DGErrors.NOTHING_TO_CLAIM.selector);
        dgBankrollManager.claimProfit(address(bankroll));
    }


    function test_blockBankroll() public {
        vm.prank(admin);
        bankroll.credit(1_000_000, operator);

        dgBankrollManager.blockBankroll(address(bankroll));

        vm.expectRevert(DGErrors.BANKROLL_NOT_APPROVED.selector);
        dgBankrollManager.claimProfit(address(bankroll));
    }
}
