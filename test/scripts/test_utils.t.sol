// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

/* Bankroll Utils */
import {Credit} from "script/utils/Bankroll/credit.s.sol";
import {Debit} from "script/utils/Bankroll/debit.s.sol";
import {DepositFunds} from "script/utils/Bankroll/deposit-funds.s.sol";
import {WithdrawFunds} from "script/utils/Bankroll/withdraw-funds.s.sol";

/* Bankroll Manager Utils */
import {AddBankroll} from "script/utils/DGBankrollManager/add-bankroll.s.sol";
import {AddOperator} from "script/utils/DGBankrollManager/add-operator.s.sol";
import {BlockBankroll} from "script/utils/DGBankrollManager/block-bankroll.s.sol";
import {BlockOperator} from "script/utils/DGBankrollManager/block-operator.s.sol";
import {ClaimProfit} from "script/utils/DGBankrollManager/claim-profit.s.sol";

/* Bankroll Factory Utils */
import {CreateBankroll} from "script/utils/DGBankrollFactory/create-bankroll.s.sol";

/* MockToken Utils */
import {MintTokens} from "script/utils/MockToken/mint-token.s.sol";

contract UtilTest is Test {
    Credit creditCall;
    Debit debitCall;
    DepositFunds depositFundsCall;
    WithdrawFunds withdrawFundsCall;

    AddBankroll addBankrollCall;
    AddOperator addOperatorCall;
    BlockBankroll blockBankrollCall;
    BlockOperator blockOperaotrCall;
    ClaimProfit claimProfitCall;

    CreateBankroll createBankrollCall;

    MintTokens mintTokensCall;

    function setUp() public {
        creditCall = new Credit();
        debitCall = new Debit();
        depositFundsCall = new DepositFunds();
        withdrawFundsCall = new WithdrawFunds();

        addBankrollCall = new AddBankroll();
        addOperatorCall = new AddOperator();
        blockBankrollCall = new BlockBankroll();
        blockOperaotrCall = new BlockOperator();
        claimProfitCall = new ClaimProfit();

        createBankrollCall = new CreateBankroll();

        mintTokensCall = new MintTokens();
    }

    // function test_creditCall() public{
        // creditCall.run();
    // }

    // function test_debitCall() public {
        // debitCall.run();
    // }

    function test_mintTokensCall() public {
        mintTokensCall.run();
    }
}