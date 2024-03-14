// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title DGDataTypes
 * @author DeGaming Technical Team
 * @notice Library containing DeGaming contracts' custom data types
 */
library DGDataTypes {
    /// @dev Enum for holding LP status
    enum LpIs {
        OPEN,
        WHITELISTED
    }

    /// @dev Withdrawal window timestamps
    struct WithdrawalInfo {
        uint256 timestampMin;
        uint256 timestampMax;
        uint256 amountToClaim;
        WithdrawalIs stage;
    }

    /// @dev Withdrawal stage
    enum WithdrawalIs {
        FULLFILLED,
        STAGED
    }
}