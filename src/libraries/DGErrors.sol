// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DGErrors
 * @author DeGaming Technical Team
 * @notice Library containing DeGaming contracts' custom errors
 */
library DGErrors {
    error SENDER_IS_NOT_A_MANAGER();
    
    error LP_IS_NOT_WHITELISTED();
    
    error SENDER_IS_NOT_AN_ADMIN();
    
    error NO_PROFIT();
}