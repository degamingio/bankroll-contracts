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

contract DGBankrollManager is Ownable {
    /// @dev basis points denominator used for percentage calculation
    uint256 public constant DENOMINATOR = 10_000;

    /// @dev Event period, the minimum time between each claim
    uint256 public constant EVENT_PERIOD = 30 days;

    /// @dev store bankroll status
    mapping(address bankroll => bool isApproved) public bankrollStatus;

    /// @dev store the fee schema for a given bankroll
    mapping(address bankroll => DGDataTypes.Fee fee) public bankrollFees;

    /// @dev store the bankroll addresses for the stakeholders
    mapping(address bankroll => DGDataTypes.StakeHolders addresses) public stakeHolderAddresses;

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

        // Set the remove bankroll fee information
        bankrollFees[_bankroll] = DGDataTypes.Fee(0, 0, 0, 0);

        // Emit FeeUpdated event
        emit DGEvents.FeeUpdated(_bankroll, 0, 0, 0, 0);
    }

    /**
     * @notice
     *  Allows a bankroll to set their fees
     *  Only the contract owner can execute this operation
     *
     * @param _bankroll address of bankroll
     * @param _deGamingFee fees in percentages to DeGaming
     * @param _bankRollFee fees in percentages to the bankroll, i.e. the LPs
     * @param _gameProviderFee fees in percentages to the game provider
     * @param _managerFee fees in percentages to the manager
     *
     */
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

        // Set the bankroll fee information
        bankrollFees[_bankroll] = DGDataTypes.Fee(_deGamingFee, _bankRollFee, _gameProviderFee, _managerFee);

        // Emit FeeUpdated event
        emit DGEvents.FeeUpdated(_bankroll, _deGamingFee, _bankRollFee, _gameProviderFee, _managerFee);
    }

    /**
     * @notice
     *  Allows a bankroll to set their stakeholder addresses
     *  Only the contract owner can execute this operation
     *
     * @param _deGaming address of DeGaming
     * @param _bankRoll address of the bankroll
     * @param _gameProvider address of the game provider
     * @param _manager address of the manager
     *
     */
    function setStakeholderAddresses(
        address _deGaming,
        address _bankroll,
        address _gameProvider,
        address _manager
    ) external onlyOwner {
        // Set bankroll stakeholder addresses
        stakeHolderAddresses[_bankroll] = DGDataTypes.StakeHolders(_deGaming, _gameProvider, _manager);

        // Emit event stakeholders  updated
        emit DGEvents.StakeholdersUpdated(_deGaming, _bankroll, _gameProvider, _manager);
    }

    /**
     * @notice Claim profit from the bankroll
     * Called by an authorized manager
     * @param _bankroll address of bankroll 
     * @param _token address of token
     *
     */
    function claimProfit(address _bankroll, address _token) external {
        // Set up a token instance
        IERC20 token = IERC20(_token);

        // Check if eventperiod has passed
        if (block.timestamp < eventPeriodEnds[_bankroll]) revert DGErrors.EVENT_PERIOD_NOT_PASSED();
        
        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[_bankroll]) revert DGErrors.BANKROLL_NOT_APPROVED();

        // Set up GGR for desired bankroll
        int256 GGR = IBankroll(_bankroll).GGR();

        // Check if Casino GGR is posetive
        if (GGR < 1) revert DGErrors.NOTHING_TO_CLAIM();

        // Get Bankroll Fee information
        DGDataTypes.Fee memory feeInfo = bankrollFees[_bankroll];

        // Get stakeholder addresses
        DGDataTypes.StakeHolders memory addressOf = stakeHolderAddresses[_bankroll];

        // Update event period ends unix timestamp to one <EVENT_PERIOD> from now
        eventPeriodEnds[_bankroll] = block.timestamp + EVENT_PERIOD;

        // Calculate fees based on the GGR
        uint256 feeToDeGaming = uint256(GGR) * feeInfo.deGaming / DENOMINATOR;
        //uint256 feeToBankRoll = uint256(GGR) * feeInfo.bankRoll / DENOMINATOR;
        uint256 feeToGameProvider = uint256(GGR) * feeInfo.gameProvider / DENOMINATOR; 
        uint256 feeToManager = uint256(GGR) * feeInfo.manager / DENOMINATOR;

        // Transfer Fees
        token.transferFrom(_bankroll, addressOf.deGaming, feeToDeGaming);
        token.transferFrom(_bankroll, addressOf.gameProvider, feeToGameProvider);
        token.transferFrom(_bankroll, addressOf.manager, feeToManager);
    
        // Should add some way to make it clear that this is a part of lp
        //token.transferFrom(_bankroll, _bankroll, feeToBankRoll);

        // Zero out the GGR
        IBankroll(_bankroll).nullGGR();
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Allows anyone to see the fees calculated from the GGR for
     *  all stakeholders by specific bankroll
     *
     * @param _bankroll the address of bankroll we want to check
     *
     * @return _claimableDeGaming claimable amount for DeGaming
     * @return _claimableBankroll claimable amount for Bankroll
     * @return _claimableGameProvider  claimable amount for Game Provider
     * @return _claimableManager claimable amount for Manager
     * @return _stakeHolderAddresses custom datatype which holds all addresses, added to simply keep track of context
     *
     */
    function claimableAmountByBankroll(address _bankroll) external view returns (
        int256 _claimableDeGaming,
        int256 _claimableBankroll,
        int256 _claimableGameProvider,
        int256 _claimableManager,
        DGDataTypes.StakeHolders memory _stakeHolderAddresses
    ) {
        // Get the GGR for the desired Bankroll
        int256 GGR = IBankroll(_bankroll).GGR();

        // Get the bankroll fee information
        DGDataTypes.Fee memory feeInfo = bankrollFees[_bankroll];

        // calculate current ggr rate
        _claimableDeGaming = GGR * int64(feeInfo.deGaming) / int(DENOMINATOR);
        _claimableBankroll = GGR * int64(feeInfo.bankRoll) / int(DENOMINATOR);
        _claimableGameProvider = GGR * int64(feeInfo.gameProvider) / int(DENOMINATOR);
        _claimableManager = GGR * int64(feeInfo.manager) / int(DENOMINATOR);

        // Fetch stakeholder addresses
        _stakeHolderAddresses = stakeHolderAddresses[_bankroll];
    }
}