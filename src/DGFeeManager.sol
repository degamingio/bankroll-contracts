// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";
import {DGErrors} from "src/libraries/DGErrors.sol";

contract DGFeeManager is Ownable {
    /// @dev basis points denominator used for percentage calculation
    uint256 public constant DENOMINATOR = 10_000;

    /// @dev Event period, the minimum time between each claim
    uint256 public constant EVENT_PERIOD = 30 days;

    /// @dev store bankroll status
    mapping(address bankroll => bool isApproved) public bankrollStatus;

    /// @dev store the fee schema for a given bankroll
    mapping(address bankroll => DGDataTypes.Fee fee) public bankrollFees;

    function approveBankroll(address _bankroll) external onlyOwner {
        bankrollStatus[_bankroll] = true;
    }

    function blockBankroll(address _bankroll) external onlyOwener {
        bankrollStatus[_bankroll] = false;

        bankrollFees[_bankroll] = DGDataTypes.Fee(0, 0, 0, 0);

        emit DGEvents.FeeUpdated(_bankroll, 0, 0, 0, 0);
    }

    function setBankrollFees(
        address _bankroll,
        uint64 deGamingFee,
        uint64 bankRollFee,
        uint64 gameProviderFee,
        uint64 managerFee
    ) external onlyOwner {
        // Ensure that cumulative fees equal 100%
        if (_deGamingFee + _gameDevFee + _operatorFee + _liquidityProviderFee != DENOMINATOR) {
            revert DGErrors.INVALID_PARAMETER();
        }

        bankrollFees[_bankroll] = DGDataTypes.Fee(deGamingFee, bankRollFee, gameProviderFee, managerFee);

        emit DGEvents.FeeUpdated(_bankroll, deGamingFee, bankRollFee, gameProviderFee, managerFee);
    }
}