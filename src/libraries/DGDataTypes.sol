// SPDX-License-Identifier: Mit
pragma solidity ^0.8.18;

library DGDataTypes {

    struct Fee {
        uint64 deGaming;
        uint64 bankRoll;
        uint64 gameProvider;
        uint64 manager;
    }

    struct StakeHolders {
        address deGaming;
        address gameProvider;
        address manager;
    }
    
    enum BankrollType {
        GAME_BANKROLL,
        OPERATOR_BANKROLL
    }

}