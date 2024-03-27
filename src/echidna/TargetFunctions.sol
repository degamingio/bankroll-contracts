// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {BeforeAfter} from "./BeforeAfter.sol";
import {Properties} from "./Properties.sol";
import "../../lib/properties/contracts/util/Hevm.sol";
import {Setup} from "./Setup.sol";

abstract contract TargetFunctions is Setup, Properties, BeforeAfter {
    function testDepositFunds(uint256 amount) public {
        amount = clampBetween(amount, 0, 100000e6);
        _initMint(msg.sender, amount);
        __before(msg.sender);

        uint256 shares = _getAmountToShares(amount);
        hevm.prank(msg.sender);
        mockToken.approve(address(bankroll), amount);

        hevm.prank(msg.sender);
        try bankroll.depositFunds(amount) {
            __after(msg.sender);
            sumOfShares += shares;
            uint256 sumOfTokens = _getSharesToAmount(sumOfShares);
            assertWithMsg(invariant_liquidityGteShares(sumOfTokens), "BKR1 | Liquidity Gte Shares");
            _checkDepositProperties(
                amount,
                shares,
                _before.userBalanceShares,
                _after.userBalanceShares,
                _before.totalSupply,
                _after.totalSupply
            );
        } catch {
            assert(false);
        }
    }

    function testWithdrawalStages(uint256 _amount) public {
        if (bankroll.sharesOf(msg.sender) == 0) {
            return;
        }
        uint256 _shares = bankroll.sharesOf(msg.sender);
        uint256 amount = clampBetween(_amount, 1, _shares);
        // emit LogUint("Amount: ", amount);
        __before(msg.sender);
        hevm.prank(msg.sender);
        try bankroll.withdrawalStageOne(amount) {
            __after(msg.sender);
        } catch {
            assert(false);
        }
        hevm.warp(block.timestamp + 3 minutes);
        hevm.prank(msg.sender);
        try bankroll.withdrawalStageTwo() {
            __after(msg.sender);
            uint256 _shares = _getAmountToShares(amount);
            sumOfShares -= _shares;
            uint256 sumOfTokens = _getSharesToAmount(sumOfShares);
            hevm.warp(block.timestamp + 1 hours);
            assertWithMsg(invariant_liquidityGteShares(sumOfTokens), "BKR1 | Liquidity Gte Shares");
        } catch {
            assert(false);
        }
    }
}
