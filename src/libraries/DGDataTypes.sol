// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DGDataTypes
 * @author DeGaming Technical Team
 * @notice Library containing DeGaming contracts' custom data types
 */
library DGDataTypes {
    /// @dev Enum for specifying events
    enum EventSpecifier {
        FUNDS_DEPOSITED,
        FUNDS_WITHDRAWN,
        DEBIT,
        CREDIT,
        BANKROLL_SWEPT
    }

    /// @dev Enum for holding LP status
    enum LpIs {
        OPEN,
        WHITELISTED
    }
}