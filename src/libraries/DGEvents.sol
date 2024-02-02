// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library DGEvents {
    event FundsDeposited(address lp, uint256 amount);
    event FundsWithdrawn(address lp, uint256 amount);
    
    /// @dev Event emitted when debit function is called
    event Debit(address manager, address player, uint256 amount);
    
    /// @dev Event emitted when Credit function is called
    event Credit(address manager, uint256 amount);
    
    event ProfitClaimed(address manager, uint256 amount);
    
    /// @dev Event emitted when the bankroll is emptied or reached max risk
    event BankrollSwept(address player, uint256 amount);
    
    /// @dev Event emitted when the stakeholder fee are updated
    event FeeUpdated(
        address bankroll, 
        uint64 deGamingFee,
        uint64 bankRollFee, 
        uint64 gameProviderFee, 
        uint64 managerFee
    );
}
