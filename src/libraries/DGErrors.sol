// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

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

    /// @dev Error thrown if we are trying to update a role with the previous role holder not being valid
    error ADDRESS_DOES_NOT_HOLD_ROLE();

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

    /// @dev Error thrown when max risk is to high
    error MAXRISK_TO_HIGH();

    /// @dev Error thrown when withdrawal queue is full
    error WITHDRAWAL_QUEUE_FULL();

    /// @dev Error thrown when withdrawal queue is empty
    error WITHDRAWAL_QUEUE_EMPTY();

    /// @dev Error thrown when withdrawal timestamp hasnt passed
    error WITHDRAWAL_TIMESTAMP_HASNT_PASSED();
}