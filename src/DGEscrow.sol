// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/* DeGaming Interfaces */
import {IDGBankrollManager} from "src/interfaces/IDGBankrollManager.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";

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

    function escrowFunds(address _player, address _operator, address _token, uint256 _winnings) external onlyRole(BANKROLL_MANAGER) {
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
        uint256 winnigns = balanceAfter - balanceBefore;

        // Set mapping for how much is held for specific id
        escrowed[id] = winnings;

        // Emit Winnings Escrowed event
        emit DGEvents.WinningsEscrowed(_bankroll, _operator, _player, _token, id);
    }

    function releaseFunds(bytes memory _id) external onlyRole(ADMIN) {
        // Check so that there are funds to claim for id
        if (escrowed[id] == 0) revert DGErrors.NOTHING_TO_CLAIM();

        // Decode id into an entry
        DGDataTypes.EscrowEntry memory entry = _decode(_id);

        // Setup token instance
        IERC20 token = IERC20(entry.token);

        // Fetch balance before releasing the funds
        uint256 balanceBefore = token.balanceOf(address(this));

        // Send the escrowed funds to the player
        token.safeTransfer(entry.player, escrowed[id]);

        // Fetch balance after the funds are released
        uint256 balanceAfter = token.balanceOf(address(this));

        // Setting the amount from the diff between the two
        uint256 amount = balanceBefore - balanceAfter;

        // Subtract the amount fetched from the escrowed mapping, probably nulling it out
        escrowed[id] -= amount;

        // Emit event stating that the escrow is payed out
        emit DGEvents.EscrowPayed(msg.sender, _id, amount);
    }

    function revertFunds(bytes memory _id) external onlyRole(ADMIN) {
        if (escrowed[id] == 0) revert DGErrors.NOTHING_TO_CLAIM();

        DGDataTypes.EscrowEntry memory entry = _decode(_id);

        IERC20 token = IERC20(entry.token);

        uint256 balanceBefore = token.balanceOf(address(this));

        token.safeTransfer(entry.bankroll, escrowed[id]);

        uint256 balanceAfter = token.balanceOf(address(this));

        uint256 amount = balanceBefore - balanceAfter;

        escrowed[id] -= amount;

        emit DGEvents.EscrowReverted(entry.bankroll, _id, amount);
    }

    function claimUnaddressed(bytes memory _id) external {
        if (escrowed[id] == 0) revert DGErrors.NOTHING_TO_CLAIM();

        DGDataTypes.EscrowEntry memory entry = _decode(id);

        if (block.timestamp > entry.timestamp + eventPeriod) revert DGErrors.EVENT_PERIOD_NOT_PASSED();

        // Check so that msg.sender is the player of the entry
        if (msg.sender != entry.player) revert DGErrors.UNAUTHORIZED_CLAIM();

        IERC20 token = IERC20(entry.token);

        uint256 balanceBefore = token.balanceOf(address(this));

        token.safeTransfer(msg.sender, escrowed[id]);

        uint256 balanceAfter = token.balanceOf(address(this));

        uint256 amount = balanceBefore - balanceAfter;

        escrowed[id] -= amount;

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

    function setBankrollManager(address _dgBankrollManager) external {
        dgBankrollManager = IDGBankrollManager(_dgBankrollManager);

        _grantRole(BANKROLL_MANAGER, _dgBankrollManager);
    }

    function _decode(bytes memory _id) internal pure returns (DGDataTypes.EscrowEntry memory _entry) {
        _entry = abi.decode(_id, (DGDataTypes.EscrowEntry));
    }
}