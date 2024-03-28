// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Setup} from "./Setup.sol";
import {PropertiesAsserts} from "../../lib/properties/contracts/util/PropertiesHelper.sol";

abstract contract Properties is Setup, PropertiesAsserts {
    function invariant_liquidityGteShares(uint256 sharesToTokens) internal view returns (bool) {
        uint256 liquidity = bankroll.liquidity();
        // uint256 shares = sumOfShares;

        return liquidity >= sharesToTokens;
    }

    function invariant_balanceGteGGR() internal view returns (bool) {
        uint256 balance = mockToken.balanceOf(address(bankroll));
        int256 ggr = bankroll.GGR();

        return int256(balance) >= ggr;
    }

    function invariant_ggrEqualSumGgrOf() internal view returns (bool) {
        int256 ggr = bankroll.GGR();

        return ggr == sumOfGgr;
    }
    // Invariant: Winning amount should always be less than the bankroll balance
    function invariant_winningsLteBalance() internal view returns (bool) {

    }

    function invariant005() internal returns (bool) {}

    function invariant006() internal view returns (bool) {}

    function _checkDepositProperties(
        uint256 deposit,
        uint256 shares,
        uint256 sharesOfBefore,
        uint256 sharesOfAfter,
        uint256 totalSupplyBefore,
        uint256 totalSupplyAfter
    ) internal {
        assertWithMsg(sharesOfAfter == sharesOfBefore + shares, "DP-1");
        assertWithMsg(totalSupplyAfter == totalSupplyBefore + shares, "DP-2");
        if (deposit > 0) assertWithMsg(shares > 0, "DP-3");
        if (deposit == 0) assertWithMsg(shares == 0, "DP-4");
    }

    function _checkWithdrawProperties(
        uint256 shares,
        uint256 tokens,
        uint256 balanceBefore,
        uint256 balanceAfter,
        uint256 totalSupplyBefore,
        uint256 totalSupplyAfter
    ) internal {
        assertWithMsg(balanceAfter == balanceBefore + tokens, "WP-1");
        assertWithMsg(totalSupplyAfter == totalSupplyBefore - shares, "WP-2");
        if (shares > 0) assertWithMsg(tokens > 0, "WP-3");
        if (shares == 0) assertWithMsg(tokens == 0, "WP-4");
    }
}
