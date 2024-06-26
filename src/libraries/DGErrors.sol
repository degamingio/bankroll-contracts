// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title DGErrors
 * @author DeGaming Technical Team
 * @notice Library containing DeGaming contracts' custom errors
 */
library DGErrors {
    /// @dev Error thrown if LP is not on the whitelist
    error LP_IS_NOT_WHITELISTED();
    
    /// @dev Error thrown when someone tries to claim fees before the eventperiod is over
    error EVENT_PERIOD_NOT_PASSED();

    /// @dev Error thrown if bankroll is not an approved DeGaming bankroll
    error BANKROLL_NOT_APPROVED();

    /// @dev Error thrown if GGR < 1 or even negative
    error NOTHING_TO_CLAIM();

    /// @dev Error thrown when address sent to credit/debit is not a valid operator
    error NOT_AN_OPERATOR();

    /// @dev Error thrown when lp has no access
    error NO_LP_ACCESS_PERMISSION();

    /// @dev Error thrown when bankroll with a > 100% fee is being requested to be added  
    error TO_HIGH_FEE();

    /// @dev Error thrown if operator is not associated with this specific bankroll
    error OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL();

    /// @dev Error thrown when trying to redundantly add operators to bankrolls
    error OPERATOR_ALREADY_ADDED_TO_BANKROLL();

    /// @dev Error thrown when LP is trying to withdraw more than they have
    error LP_REQUESTED_AMOUNT_OVERFLOW();

    /// @dev Error thrown when a bankroll has a minimum lp amount which the depositor does not satisfy
    error DEPOSITION_TO_LOW();

    /// @dev Error thrown when desired bankroll is not a contract
    error ADDRESS_NOT_A_CONTRACT();

    /// @dev Error thrown when desired operator is not a wallet
    error ADDRESS_NOT_A_WALLET();

    /// @dev Error thrown when max risk is too high
    error MAXRISK_TOO_HIGH();

    /// @dev Error thrown when withdrawal timestamp hasnt passed
    error WITHDRAWAL_TIMESTAMP_HASNT_PASSED();

    /// @dev Error thrown when withdrawal is in staging mode
    error WITHDRAWAL_PROCESS_IN_STAGING();

    /// @dev Error thrown when trying to fullfill an already fullfilled withdrawal
    error WITHDRAWAL_ALREADY_FULLFILLED();

    /// @dev Error thrown when LPs are trying to withdraw outside of their withdrawal window
    error OUTSIDE_WITHDRAWAL_WINDOW();

    /// @dev Error thrown when someone unauthorized is trying to claim
    error UNAUTHORIZED_CLAIM();

    /// @dev Error thrown if maxrisk = 0
    error MAX_RISK_ZERO();

    /// @dev Error thrown if checks regarding setting withdrawal mechanisms params fail
    error WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

    /// @dev Error thrown if a lp is tryingto withdraw when withdrawals are stopped
    error WITHDRAWALS_NOT_ALLOWED();

    /// @dev Error thrown when withdrawal delay is under 30 seconds
    error WITHDRAWAL_DELAY_TO_SHORT();

    /// @dev Error thrown when escrow is locked
    error ESCROW_LOCKED();

    /// @dev Error thrown when minimum deposition time of LP hasn't passed
    error MINIMUM_DEPOSITION_TIME_NOT_PASSED();
}
