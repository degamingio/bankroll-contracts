// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Bankroll} from "src/Bankroll.sol";

import {IBankroll} from "src/interfaces/IBankroll.sol";

import {DGEvents} from "src/libraries/DGEvents.sol";
import {DGErrors} from "src/libraries/DGErrors.sol";

/**
 * @title DGBankrollManager
 * @author DeGaming Technical Team
 * @notice Fee management of GGR 
 *
 */
contract DGBankrollManager is Ownable {
    //Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

    /// @dev Event period, the minimum time between each claim
    uint256 public constant EVENT_PERIOD = 30 days;

    /// @dev DeGaming Wallet
    address deGaming;

    /// @dev Set up bankroll instance
    IBankroll bankroll;

    /// @dev store bankroll status
    mapping(address bankroll => bool isApproved) public bankrollStatus;

    /// @dev mapping that stores all operators associated with a bankroll
    mapping(address bankroll => address[] operator) public operatorsOf;

    /// @dev Store time claimed + event period
    mapping(address claimer => uint256 timestamp) public eventPeriodEnds;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice DGBankrollManager constructor
     *   Just sets the deployer of this contract as the owner
     */
    constructor() Ownable(msg.sender) {}

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Approve a bankroll to use the DeGaming Bankroll Manager
     *  Only the contract owner can execute this operation
     *
     * @param _bankroll bankroll contract address to be approved
     *
     */
    function approveBankroll(address _bankroll) external onlyOwner {
        // Toggle bankroll status
        bankrollStatus[_bankroll] = true;
    }

    /**
     * @notice
     *  Prevent a bankroll from using the DeGaming Bankroll Manager
     *  Only the contract owner can execute this operation
     *
     * @param _bankroll bankroll contract address to be blocked
     *
     */
    function blockBankroll(address _bankroll) external onlyOwner {
        // Toggle bankroll status
        bankrollStatus[_bankroll] = false;
    }

    function setOperatorToBankroll(address _bankroll, address _operator) external onlyOwner  {
        operatorsOf[_bankroll].push(_operator);
    }


    /**
     * @notice Claim profit from the bankroll
     * 
     * @param _bankroll address of bankroll 
     *
     */
    function claimProfit(address _bankroll) external {        
        // Check if eventperiod has passed
        if (block.timestamp < eventPeriodEnds[_bankroll]) revert DGErrors.EVENT_PERIOD_NOT_PASSED();

        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[_bankroll]) revert DGErrors.BANKROLL_NOT_APPROVED();
        
        address[] memory operators = operatorsOf[_bankroll];

        bankroll = IBankroll(_bankroll);
        
        //// Set up a token instance
        IERC20 token = IERC20(bankroll.viewTokenAddress());
        
        // Set up GGR for desired bankroll
        int256 GGR = bankroll.GGR();

        // Check if Casino GGR is posetive
        if (GGR < 1) revert DGErrors.NOTHING_TO_CLAIM();

        // Update event period ends unix timestamp to one <EVENT_PERIOD> from now
        eventPeriodEnds[_bankroll] = block.timestamp + EVENT_PERIOD;

        for (uint256 i = 0; i >= operators.length; i++) {
            token.safeTransferFrom(
                address(_bankroll), 
                address(deGaming), 
                uint256(bankroll.ggrOf(operators[i]))
            );

            // Zero out the GGR
            bankroll.nullGgrOf(operators[i]);
        }
    }
}