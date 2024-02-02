// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library DGEvents {
    event FundsDeposited(address lp, uint256 amount);
    event FundsWithdrawn(address lp, uint256 amount);
    event Debit(address manager, address player, uint256 amount);
    event Credit(address manager, uint256 amount);
    event ProfitClaimed(address manager, uint256 amount);
    event BankrollSwept(address player, uint256 amount);
}
