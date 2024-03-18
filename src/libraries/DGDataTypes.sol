// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

    /// @dev Enum for holding withdrawal stage
    enum WithdrawalIs {
        FULLFILLED,
        STAGED
    }

    /// @dev Withdrawal window timestamps
    struct WithdrawalInfo {
        uint256 timestamp;
        uint256 amountToClaim;
        WithdrawalIs stage;
    }

    /// @dev Escrow entry 
    struct EscrowEntry {
        address bankroll;
        address operator;
        address player;
        address token;
        uint256 timestamp;
    }
}