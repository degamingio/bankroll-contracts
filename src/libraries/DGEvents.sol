// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title DGEvents
 * @author DeGaming Technical Team
 * @notice Library containing DeGaming contracts' custom events
 */
library DGEvents {
    /// @dev Event emitted when LPs have deposited funds
    event FundsDeposited(address bankroll, address lp, uint256 amount);

    /// @dev Event emitted when LPs have withdrawn funds
    event FundsWithdrawn(address bankroll, address lp, uint256 amount);
    
    /// @dev Event emitted when debit function is called
    event Debit(address bankroll, address manager, address player, uint256 amount);
    
    /// @dev Event emitted when Credit function is called
    event Credit(address bankroll, address manager, uint256 amount);
    
    /// @dev Event emitted when the bankroll is emptied or reached max risk
    event BankrollSwept(address bankroll, address player, uint256 amount);

    /// @dev Event emitted when profits are claimed
    event ProfitsClaimed(address bankroll, uint256 ggrTotal, uint256 sentToDeGaming);
}
