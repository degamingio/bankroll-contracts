// SPDX_License_Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title DGEscrow
 * @author DeGaming Technical Team
 * @notice Escrow Contract for DeGaming's Bankroll poducts
 *
 */
interface IDGEscrow {

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Function called by the bankroll to send funds to the escrow
     *
     * @param _player address of the player 
     * @param _operator address of the operator
     * @param _token address of the token
     * @param _winnings amount of tokens sent to escrow
     *
     */
    function depositFunds(address _player, address _operator, address _token, uint256 _winnings) external; 

    /**
     * @notice
     *  Allows DeGaming to release escrowed funds to the player wallet
     *
     * @param _id id in bytes format
     *
     */
    function releaseFunds(bytes memory _id) external;

    /**
     * @notice
     *  Allows DeGaming to revert escrowed funds back into the bankroll in case of fraud
     *
     * @param _id id in bytes format
     *
     */
    function revertFunds(bytes memory _id) external;

    /**
     * @notice
     *  Allows admin to set the lock status of escrowed funds
     *
     * @param _id id of escrowed funds
     * @param _status boolean status if the funds should be locked or not
     *
     */
    function toggleLockEscrow(bytes memory _id, bool _status) external;

    /**
     * @notice
     *  Allows players to claim their escrowed amount after a certain period has passed
     *  id escrow is left unaddressed by DeGaming
     *
     * @param _id id in bytes format
     *
     */
    function claimUnaddressed(bytes memory _id) external;

    /**
     * @notice 
     *  Allows admin to set new event period time
     *
     * @param _newEventPeriod New event period time in seconds
     *
     */
    function setEventPeriod(uint256 _newEventPeriod) external;
}