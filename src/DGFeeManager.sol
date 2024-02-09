// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IBankroll} from "src/interfaces/IBankroll.sol";

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

    /// @dev Store time claimed + event period
    mapping(address claimer => uint256 timestamp) public eventPeriodEnds;

    function approveBankroll(address _bankroll) external onlyOwner {
        bankrollStatus[_bankroll] = true;
    }

    function blockBankroll(address _bankroll) external onlyOwner {
        bankrollStatus[_bankroll] = false;

        bankrollFees[_bankroll] = DGDataTypes.Fee(0, 0, 0, 0);

        emit DGEvents.FeeUpdated(_bankroll, 0, 0, 0, 0);
    }

    function setBankrollFees(
        address _bankroll,
        uint64 _deGamingFee,
        uint64 _bankRollFee,
        uint64 _gameProviderFee,
        uint64 _managerFee
    ) external onlyOwner {
        // Ensure that cumulative fees equal 100%
        if (_deGamingFee + _bankRollFee + _gameProviderFee + _managerFee != DENOMINATOR) {
            revert DGErrors.INVALID_PARAMETER();
        }

        bankrollFees[_bankroll] = DGDataTypes.Fee(_deGamingFee, _bankRollFee, _gameProviderFee, _managerFee);

        emit DGEvents.FeeUpdated(_bankroll, _deGamingFee, _bankRollFee, _gameProviderFee, _managerFee);
    }

    /**
     * @notice Claim profit from the bankroll
     * Called by an authorized manager
     */
    function claimProfit(address _bankroll, address _token) external {
        // Set up a token instance
        IERC20 token = IERC20(_token);

        // Check if eventperiod has passed
        if (block.timestamp < eventPeriodEnds[_bankroll]) revert DGErrors.EVENT_PERIOD_NOT_PASSED();
        
        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[_bankroll]) revert DGErrors.BANKROLL_NOT_APPROVED();

        // Set up GGR for desired bankroll
        int256 GGR = IBankroll(_bankroll);

        // Check if Casino GGR is posetive
        if (GGR < 1) revert DGErrors.NOTHING_TO_CLAIM();

        // Get Bankroll Fee information
        DGDataTypes.Fee memory feeInfo = bankrollFees[_bankroll];

        uint256 feeToDeGaming = uint256(GGR) * feeInfo.deGaming / DENOMINATOR;
        uint256 feeToBankRoll = uint256(GGR) * feeInfo.bankRoll / DENOMINATOR;
        uint256 feeToGameProvider = uint256(GGR) * feeInfo.gameProvider / DENOMINATOR; 
        uint256 feeToManager = uint256(GGR) * feeInfo.manager / DENOMINATOR;

        token.transferFrom(_bankroll, to, feeToDeGaming);
        token.transferFrom(_bankroll, to, feeToBankRoll);
        token.transferFrom(_bankroll, to, feeToGameProvider);
        token.transferFrom(_bankroll, to, feeTofeeToManager);
    }
}