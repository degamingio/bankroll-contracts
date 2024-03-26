// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import "../../lib/properties/contracts/util/Hevm.sol";
import {Setup} from "./Setup.sol";

abstract contract TargetFunctions is Setup, Properties, BeforeAfter {
    function testDepositFunds(uint256 amount) public {
        _initMint(msg.sender, amount);
        __before(msg.sender);
        uint256 shares = _getAmountToShares(amount);

        hevm.prank(msg.sender);
        try bankroll.depositFunds(amount) {
            __after(msg.sender);
            sumOfShares += shares;
            assertWithMsg(invariant_liquidityGteShares(sumOfShares), "BKR1 | Liquidity Gte Shares");
        } catch {
            assert(false);
        }
    }

    // function testWithdraw(uint256 shares) public {}
}
