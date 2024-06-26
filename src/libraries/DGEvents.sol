// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title DGEvents
 * @author DeGaming Technical Team
 * @notice Library containing DeGaming contracts' custom events
 */
library DGEvents {
    /// @dev Event emitted when LPs have deposited funds
    event FundsDeposited(address lp, uint256 amount);

    /// @dev Event emitted when LPs have withdrawn funds
    event FundsWithdrawn(address lp, uint256 amount);

    /// @dev Event emitted when LP withdrawal is staged;
    event WithdrawalStaged(address lp, uint256 timestampMin, uint256 timestampMax);
    
    /// @dev Event emitted when debit function is called
    event Debit(address manager, address player, uint256 amount);
    
    /// @dev Event emitted when Credit function is called
    event Credit(address manager, uint256 amount);
    
    /// @dev Event emitted when the bankroll is emptied or reached max risk
    event BankrollSwept(address player, uint256 amount);

    /// @dev Event emitted when profits are claimed
    event ProfitsClaimed(address bankroll, uint256 ggrTotal, uint256 sentToDeGaming);

    /// @dev Event emitted when funds are escrowed
    event WinningsEscrowed(address bankroll, address operator, address player, address token, bytes id);

    /// @dev Event emitted when escrow is payed out
    event EscrowPayed(address recipient, bytes id, uint256 amount);
    
    /// @dev Event emitted when escrow is payed out
    event EscrowReverted(address bankroll, bytes id, uint256 amount);
}
