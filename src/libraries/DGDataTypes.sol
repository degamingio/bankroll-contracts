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

    /// @dev Entry datatype for withdrawal queue
    struct WithdrawalEntry {
        address sender;
        uint256 amount;
    }
}