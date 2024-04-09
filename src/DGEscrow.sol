// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* Openzeppelin Interfaces */
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/* Openzeppelin Contracts */
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

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
contract DGEscrow is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev max time funds can be escrowed
    uint256 public eventPeriod;

    /// @dev nonce used to avoid ID collision
    uint256 nonce;

    /// @dev ADMIN role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev Mapping for holding the escrow info, acts as a source of truth
    mapping(bytes id => uint256 winnings) public escrowed;

    /// @dev Mapping to block an escrow
    mapping(bytes id => bool status) public lockedEscrow;

    /// @dev Bankroll manager instance
    IDGBankrollManager public dgBankrollManager;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Constructor
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
    
    /**
     * @param _eventPeriod event period in seconds
     * @param _bankrollManager address of bankrollmanager
     *
     */
    function initialize(uint256 _eventPeriod, address _bankrollManager) external initializer {
        // Set event period
        eventPeriod = _eventPeriod;

        // Make sure that bankroll manager address actully is a contract
        if (!_isContract(_bankrollManager)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        __AccessControl_init();
        __ReentrancyGuard_init();

        // Setup bankroll manager instance
        dgBankrollManager = IDGBankrollManager(_bankrollManager);

        // Granting DEFAULT_ADMIN_ROLE to the deoployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Granting ADMIN to the deoployer
        _grantRole(ADMIN, msg.sender);
    }

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
            block.timestamp,
            nonce
        );

        // Increment nonce
        nonce++;

        // Encode entry into bytes to use for id of escrow
        bytes memory id = abi.encode(entry);

        // Set up token intance
        IERC20Upgradeable token = IERC20Upgradeable(_token);

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
        IERC20Upgradeable token = IERC20Upgradeable(entry.token);

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
        IERC20Upgradeable token = IERC20Upgradeable(entry.token);

        // Fetch balance before reverting the funds back to the bankroll
        uint256 balanceBefore = token.balanceOf(address(this));

        // Approve spending for bankroll to spend on behalf of escrow contract
        token.forceApprove(entry.bankroll, escrowed[_id]);

        // Make sure that approval went through
        if (token.allowance(address(this), entry.bankroll) == escrowed[_id]) {

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

        // If we encounter some error reverting the funds back into the bankroll....
        } else {
            // ... lock the escrowed funds so that they cant be claimed through claimUnaddressed
            lockedEscrow[_id] = true;
        }
    }

    /**
     * @notice
     *  Allows admin to set the lock status of escrowed funds
     *
     * @param _id id of escrowed funds
     * @param _status boolean status if the funds should be locked or not
     *
     */
    function toggleLockEscrow(bytes memory _id, bool _status) external onlyRole(ADMIN){
        // Check so that there are funds to claim for id
        if (escrowed[_id] == 0) revert DGErrors.NOTHING_TO_CLAIM();

        // Toggle the lock status
        lockedEscrow[_id] = _status;
    }

    /**
     * @notice
     *  Allows players to claim their escrowed amount after a certain period has passed
     *  id escrow is left unaddressed by DeGaming
     *
     * @param _id id in bytes format
     *
     */
    function claimUnaddressed(bytes memory _id) external nonReentrant {
        if (lockedEscrow[_id]) revert DGErrors.ESCROW_LOCKED();

        // Check so that there are funds to claim for id
        if (escrowed[_id] == 0) revert DGErrors.NOTHING_TO_CLAIM();

        // Decode id into an entry
        DGDataTypes.EscrowEntry memory entry = _decode(_id);

        // Make sure that the event period is actually passed
        if (block.timestamp < entry.timestamp + eventPeriod) revert DGErrors.EVENT_PERIOD_NOT_PASSED();

        // Check so that msg.sender is the player of the entry
        if (msg.sender != entry.player) revert DGErrors.UNAUTHORIZED_CLAIM();

        // Send the escrowed funds back to the bankroll
        IERC20Upgradeable token = IERC20Upgradeable(entry.token);

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
     *  Allows admin to update bankroll manager contract
     *
     * @param _newBankrollManager address of the new bankroll manager
     *
     */
    function updateBankrollManager(address _newBankrollManager) external onlyRole(ADMIN) {
        // Make sure that the new bankroll manager is a contract
        if (!_isContract(_newBankrollManager)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // set the new bankroll manager
        dgBankrollManager = IDGBankrollManager(_newBankrollManager);
    }

    /**
     * @notice 
     *  Allows admin to set new event period time
     *
     * @param _newEventPeriod New event period time in seconds
     *
     */
    function setEventPeriod(uint256 _newEventPeriod) external onlyRole(ADMIN) {
        // Set eventPeriod global var
        eventPeriod = _newEventPeriod;
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
