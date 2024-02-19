// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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
}