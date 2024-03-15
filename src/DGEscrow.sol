// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/* DeGaming Interfaces */
import {IDGBankrollManager} from "src/interfaces/IDGBankrollManager.sol";
import {IBankroll} from "src/interfaces/IBankroll.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";


/**
 * @title DGEscrow
 * @author DeGaming Technical Team
 * @notice Escrow Contract for DeGaming's Bankroll poducts
 *
 */
contract DGEscrow is AccessControl {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

    /// @dev max time funds can be escrowed
    uint256 eventPeriod;

    /// @dev ADMIN role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev BANKROLL_MANAGER role
    bytes32 public constant BANKROLL_MANAGER = keccak256("BANKROLL_MANAGER");

    /// @dev Mapping for holding the escrow info, acts as a source of truth
    mapping(bytes id => uint256 winnings) public escrowed;

    /// @dev Bankroll manager instance
    IDGBankrollManager public dgBankrollManager;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    constructor(uint256 _eventPeriod, address _bankrollManager) {
        // Set event period
        eventPeriod = _eventPeriod;

        // Setup bankroll manager instance
        dgBankrollManager = IDGBankrollManager(_bankrollManager);

        // Granting DEFAULT_ADMIN_ROLE to the deoployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Granting ADMIN to the deoployer
        _grantRole(ADMIN, msg.sender);

        // Granting BANKROLL_MANAGER to the bankrollmanager address
        _grantRole(BANKROLL_MANAGER, _bankrollManager);
    }

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
    function depositFunds(address _player, address _operator, address _token, uint256 _winnings) external {
        // Make sure that bankroll is an approved bankroll of DeGaming
        if (!dgBankrollManager.bankrollStatus(msg.sender)) revert DGErrors.BANKROLL_NOT_APPROVED();

        // Create escrow entry
        DGDataTypes.EscrowEntry memory entry = DGDataTypes.EscrowEntry(
            msg.sender,
            _operator,
            _player,
            _token,
            block.timestamp
        );

        // Encode entry into bytes to use for id of escrow
        bytes memory id = abi.encode(entry);

        // Set up token intance
        IERC20 token = IERC20(_token);

        // Fetch token balance before funds are getting escrowed
        uint256 balanceBefore = token.balanceOf(address(this));

        // Transfer funds into escrow
        token.safeTransferFrom(msg.sender, address(this), _winnings);

        // Fetch token balance after funds have been escrowed
        uint256 balanceAfter = token.balanceOf(address(this));

        // Create the realized winnings from the diff between the two
        uint256 winnings = balanceAfter - balanceBefore;

        // Set mapping for how much is held for specific id
        escrowed[id] = winnings;

        // Emit Winnings Escrowed event
        emit DGEvents.WinningsEscrowed(msg.sender, _operator, _player, _token, id);
    }

    /**
     * @notice
     *  Allows DeGaming to release escrowed funds to the player wallet
     *
     * @param _id id in bytes format
     *
     */
    function releaseFunds(bytes memory _id) external onlyRole(ADMIN) {
        // Check so that there are funds to claim for id
        if (escrowed[_id] == 0) revert DGErrors.NOTHING_TO_CLAIM();

        // Decode id into an entry
        DGDataTypes.EscrowEntry memory entry = _decode(_id);

        // Setup token instance
        IERC20 token = IERC20(entry.token);

        // Fetch balance before releasing the funds
        uint256 balanceBefore = token.balanceOf(address(this));

        // Send the escrowed funds to the player
        token.safeTransfer(entry.player, escrowed[_id]);

        // Fetch balance after the funds are released
        uint256 balanceAfter = token.balanceOf(address(this));

        // Setting the amount from the diff between the two
        uint256 amount = balanceBefore - balanceAfter;

        // Subtract the amount fetched from the escrowed mapping, probably nulling it out
        escrowed[_id] -= amount;

        // Emit event stating that the escrow is payed out
        emit DGEvents.EscrowPayed(msg.sender, _id, amount);
    }

    /**
     * @notice
     *  Allows DeGaming to revert escrowed funds back into the bankroll in case of fraud
     *
     * @param _id id in bytes format
     *
     */
    function revertFunds(bytes memory _id) external onlyRole(ADMIN) {
        // Check so that there are funds to claim for id
        if (escrowed[_id] == 0) revert DGErrors.NOTHING_TO_CLAIM();

        // Decode id into an entry
        DGDataTypes.EscrowEntry memory entry = _decode(_id);

        // Setup token instance
        IERC20 token = IERC20(entry.token);

        // Fetch balance before reverting the funds back to the bankroll
        uint256 balanceBefore = token.balanceOf(address(this));

        // Send the escrowed funds back to the bankroll
        IBankroll(entry.bankroll).credit(escrowed[_id], entry.operator);

        // Fetch balance after the funds have been reverted
        uint256 balanceAfter = token.balanceOf(address(this));

        // Setting the amount from the diff between the two
        uint256 amount = balanceBefore - balanceAfter;

        // Subtract the amount fetched from the escrowed mapping, probably nulling it out
        escrowed[_id] -= amount;

        // Emit event that escrow is reverted back into the bankroll
        emit DGEvents.EscrowReverted(entry.bankroll, _id, amount);
    }

    /**
     * @notice
     *  Allows players to claim their escrowed amount after a certain period has passed
     *  id escrow is left unaddressed by DeGaming
     *
     * @param _id id in bytes format
     *
     */
    function claimUnaddressed(bytes memory _id) external {
        // Check so that there are funds to claim for id
        if (escrowed[_id] == 0) revert DGErrors.NOTHING_TO_CLAIM();

        // Decode id into an entry
        DGDataTypes.EscrowEntry memory entry = _decode(_id);

        // Make sure that the event period is actually passed
        if (block.timestamp > entry.timestamp + eventPeriod) revert DGErrors.EVENT_PERIOD_NOT_PASSED();

        // Check so that msg.sender is the player of the entry
        if (msg.sender != entry.player) revert DGErrors.UNAUTHORIZED_CLAIM();

        // Send the escrowed funds back to the bankroll
        IERC20 token = IERC20(entry.token);

        // Fetch balance before releasing the funds
        uint256 balanceBefore = token.balanceOf(address(this));

        // Send the escrowed funds to the player
        token.safeTransfer(entry.player, escrowed[_id]);

        // Fetch balance after the funds are released
        uint256 balanceAfter = token.balanceOf(address(this));

        // Setting the amount from the diff between the two
        uint256 amount = balanceBefore - balanceAfter;

        // Subtract the amount fetched from the escrowed mapping, probably nulling it out
        escrowed[_id] -= amount;

        // Emit event stating that the escrow is payed out
        emit DGEvents.EscrowPayed(msg.sender, _id, amount);
    }

    /**
     * @notice Update the ADMIN role
     *  Only calleable by contract owner
     *
     * @param _oldAdmin address of the old admin
     * @param _newAdmin address of the new admin
     *
     */
    function updateAdmin(address _oldAdmin, address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Check that _oldAdmin address is valid
        if (!hasRole(ADMIN, _oldAdmin)) revert DGErrors.ADDRESS_DOES_NOT_HOLD_ROLE();

        // Make sure so that admin address is a wallet
        if (_isContract(_newAdmin)) revert DGErrors.ADDRESS_NOT_A_WALLET();

        // Revoke the old admins role
        _revokeRole(ADMIN, _oldAdmin);

        // Grant the new admin the ADMIN role
        _grantRole(ADMIN, _newAdmin);
    }

    /**
     * @notice Update the BANKROLL_MANAGER role
     *  Only calleable by contract owner
     *
     * @param _oldBankrollManager address of the old bankroll manager
     * @param _newBankrollManager address of the new bankroll manager
     *
     */
    function updateBankrollManager(address _oldBankrollManager, address _newBankrollManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Check that _oldBankrollManager is valid
        if (!hasRole(BANKROLL_MANAGER, _oldBankrollManager)) revert DGErrors.ADDRESS_DOES_NOT_HOLD_ROLE();

        // Check so that bankroll manager actually is a contract
        if (!_isContract(_newBankrollManager)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Revoke the old bankroll managers role
        _revokeRole(BANKROLL_MANAGER, _oldBankrollManager);

        // Grant the new bankroll manager the BANKROLL_MANAGER role
        _grantRole(BANKROLL_MANAGER, _newBankrollManager);

        // Update BankrollManager Contract
        dgBankrollManager = IDGBankrollManager(_newBankrollManager);
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Decoding IDs into valid entry custom data type
     *
     * @param _id id in bytes format
     *
     * @return _entry custom dataType return which holds all escrow information
     *
     */
    function _decode(bytes memory _id) internal pure returns (DGDataTypes.EscrowEntry memory _entry) {
        _entry = abi.decode(_id, (DGDataTypes.EscrowEntry));
    }

    /**
     * @notice
     *  Allows contract to check if the Token address actually is a contract
     *
     * @param _address address we want to  check
     *
     * @return _isAddressContract returns true if token is a contract, otherwise returns false
     *
     */
    function _isContract(address _address) internal view returns (bool _isAddressContract) {
        uint256 size;

        assembly {
            size := extcodesize(_address)
        }

        _isAddressContract = size > 0;
    }
}