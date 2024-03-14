// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* DeGaming Interfaces */
import {IDGBankrollManager} from "src/interfaces/IDGBankrollManager.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";

contract DGEscrow {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

    // Mapping for holding the escrow info, acts as a source of truth
    mapping(bytes id => uint256 winnings) public escrowed;

    /// @dev Bankroll manager instance
    IDGBankrollManager public dgBankrollManager;

    function setBankrollManager(address _dgBankrollManager) external {
        dgBankrollManager = IDGBankrollManager(_dgBankrollManager);
    }

    function escrowFunds(address _player, address _operator, address _token, uint256 _winnings) external {
        DGDataTypes.EscrowEntry memory entry = DGDataTypes.EscrowEntry(
            msg.sender,
            _operator,
            _player,
            _token,
            block.timestamp
        );

        bytes memory id = abi.encode(entry);

        escrowed[id] = winnings;

        emit DGEvents.WinningsEscrowed(_bankroll, _operator, _player, _token, id);
    }

    function releaseFunds(bytes memory _id) external {
        if (escrowed[id] == 0) revert DGErrors.NOTHING_TO_CLAIM();

        DGDataTypes.EscrowEntry memory entry = _idDecode(_id);

        if (msg.sender != entry.player) revert DGErrors.UNAUTHORIZED_CLAIM();



        IERC20 token = IERC20(entry.token);
    }

    function revertFunds(bytes memory _id) external {
        if (escrowed[id] == 0) revert DGErrors.NOTHING_TO_CLAIM();
    }

    function claimUnaddressed(bytes memory _id) external {
        if (escrowed[id] == 0) revert DGErrors.NOTHING_TO_CLAIM();
    }

    function _idDecode(bytes memory _id) internal pure returns (DGDataTypes.EscrowEntry memory _entry) {
        _entry = abi.decode(_id, (DGDataTypes.EscrowEntry));
    }
}