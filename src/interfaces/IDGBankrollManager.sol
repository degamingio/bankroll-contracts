// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/**
 * @title IDGBankrollManager V1
 * @author DeGaming Technical Team
 * @notice Interface for DGBankrollManager contract
 *
 */
interface IDGBankrollManager {
    /**
     * @notice Update the ADMIN role
     *  Only calleable by contract owner
     *
     * @param _oldAdmin address of the old admin
     * @param _newAdmin address of the new admin
     *
     */
    function updateAdmin(address _oldAdmin, address _newAdmin) external;
    
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
     *  Adding list of operator to list of operators associated with a bankroll
     *  Only calleable by owner
     *
     * @param _bankroll the bankroll contract address
     * @param _operator address of the operator we want to add to the list of associated operators
     *
     */
    function setOperatorToBankroll(address _bankroll, address _operator) external;

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



    /**
     * @notice Event handler for bankrolls
     *  General event emitter function that is used from bankroll contract
     *  In order for all events to be fetched from the same place for the frontend 
     *
     * @param _eventSpecifier choose what event to emit 
     * @param _address1 first address sent to event
     * @param _address2 second address sent to event (optional that it is used) 
     * @param _number uint256 type sent to the event
     *
     */
    function emitEvent(
        DGDataTypes.EventSpecifier _eventSpecifier,
        address _address1,
        address _address2,
        uint256 _number
    ) external;

    function isApproved(address operator) external view returns(bool approved); 
} 