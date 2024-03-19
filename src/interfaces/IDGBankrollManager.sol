// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/**
 * @title IDGBankrollManager V1
 * @author DeGaming Technical Team
 * @notice Interface for DGBankrollManager contract
 *
 */
interface IDGBankrollManager {
    /**
     * @notice
     *  Approve a bankroll to use the DeGaming Bankroll Manager
     *  Only the contract owner can execute this operation
     *
     * @param _bankroll bankroll contract address to be approved
     *
     */
    function approveBankroll(address _bankroll, uint256 _fee) external;

    /**
     * @notice
     *  Prevent a bankroll from using the DeGaming Bankroll Manager
     *  Only the contract owner can execute this operation
     *
     * @param _bankroll bankroll contract address to be blocked
     *
     */
    function blockBankroll(address _bankroll) external;

    /**
     * @notice
     *  Update existing bankrolls fee
     *
     * @param _bankroll bankroll contract address to be blocked
     * @param _newFee bankroll contract address to be blocked
     *
     */
    function updateLpFee(address _bankroll, uint256 _newFee) external;

    /**
     * @notice 
     *  Adding list of operator to list of operators associated with a bankroll
     *  Only calleable by owner
     *
     * @param _bankroll the bankroll contract address
     * @param _operator address of the operator we want to add to the list of associated operators
     *
     */
    function setOperatorToBankroll(address _bankroll, address _operator) external;

    function removeOperatorFromBankroll(address _operator, address _bankroll) external;

    function blockOperator(address _operator) external;

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Claim profit from the bankroll
     * 
     * @param _bankroll address of bankroll 
     *
     */
    function claimProfit(address _bankroll) external;

    function isApproved(address operator) external view returns(bool approved); 

    function operatorOfBankroll(address _bankroll, address _operator) external view returns (bool _isRelated);

    function eventPeriodOf(address bankroll) external view returns(uint256 eventPeriod);

    function bankrollStatus(address bankroll) external view returns(bool isApproved);
} 