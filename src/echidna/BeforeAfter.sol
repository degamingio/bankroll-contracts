// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";

abstract contract BeforeAfter is Setup {
    struct Vars {
        // User variables
        uint256 userBalanceToken;
        uint256 userBalanceShares;
        // Bankroll variables
        uint256 totalSupply;
        int256 ggr;
    }

    Vars _before;
    Vars _after;

    function __before(address user) internal {
        // User variables
        _before.userBalanceToken = mockToken.balanceOf(user);
        _before.userBalanceShares = bankroll.sharesOf(user);
        // Bankroll variables
        _before.totalSupply = bankroll.totalSupply();
        _before.ggr = bankroll.GGR();
    }

    function __after(address user) internal {
        // User variables
        _after.userBalanceToken = mockToken.balanceOf(user);
        _after.userBalanceShares = bankroll.sharesOf(user);
        // Bankroll variables
        _after.totalSupply = bankroll.totalSupply();
        _after.ggr = bankroll.GGR();
    }
}
