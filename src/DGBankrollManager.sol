// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/* DeGaming Contracts */
import {Bankroll} from "src/Bankroll.sol";

/* DeGaming Interfaces */
import {IBankroll} from "src/interfaces/IBankroll.sol";
import {IDGBankrollManager} from "src/interfaces/IDGBankrollManager.sol";

/* DeGaming Libraries */
import {DGEvents} from "src/libraries/DGEvents.sol";
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/**
 * @title DGBankrollManager
 * @author DeGaming Technical Team
 * @notice Fee management of GGR 
 *
 */
contract DGBankrollManager is IDGBankrollManager, AccessControl {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

    /// @dev used to calculate percentages
    uint256 public constant DENOMINATOR = 10_000; 

    /// @dev DeGaming Wallet
    address deGaming;

    /// @dev ADMIN role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev Event period of specific bankroll
    mapping(address bankroll => uint256 eventPeriod) public eventPeriodOf;

    /// @dev store bankroll status
    mapping(address bankroll => bool isApproved) public bankrollStatus;

    /// @dev store bankroll lp fees in percentage
    mapping(address bankroll => uint256 lpFee) public lpFeeOf;

    /// @dev mapping that stores all operators associated with a bankroll
    mapping(address bankroll => address[] operator) public operatorsOf;

    /// @dev mapping that if operator is approved
    mapping(address operator => bool approved) public isApproved;

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
     *
     */
    constructor(address _deGaming) {
        // Set DeGaming global variable
        deGaming = _deGaming;

        // Grant default admin role to deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant Admin role to deployer
        _grantRole(ADMIN, msg.sender);
    }

    //     ____        __         ____                              ______                 __  _
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/
    //               /____/

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
        
        // Revoke the old admins role
        _revokeRole(ADMIN, _oldAdmin);

        // Grant the new admin the ADMIN role
        _grantRole(ADMIN, _newAdmin);
    }

    /**
     * @notice
     *  Set the address of the dg factory address
     *
     * @param _factory bankroll factory contract address to be approved
     *
     */
    function setFactory(address _factory) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that factory is a contract
        if (!_isContract(_factory)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Grant Admin Role to Factory
        _grantRole(ADMIN, _factory);
    }

    /**
     * @notice
     *  Approve a bankroll to use the DeGaming Bankroll Manager
     *  Only the admin role can execute this operation
     *
     * @param _bankroll bankroll contract address to be approved
     *
     */
    function approveBankroll(address _bankroll, uint256 _fee) external onlyRole(ADMIN) {
        // Check so that fee is withing range
        if (_fee > DENOMINATOR) revert DGErrors.TO_HIGH_FEE();
        
        // Make sure that bankroll is a contract
        if (!_isContract(_bankroll)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Toggle bankroll status
        bankrollStatus[_bankroll] = true;

        // set LP fee
        lpFeeOf[_bankroll] = _fee;
    
        // set default eventPeriod
        eventPeriodOf[_bankroll] = 30 days;
    }

    /**
     * @notice
     *  Prevent a bankroll from using the DeGaming Bankroll Manager
     *  Only the admin role can execute this operation
     *
     * @param _bankroll bankroll contract address to be blocked
     *
     */
    function blockBankroll(address _bankroll) external onlyRole(ADMIN) {
        // Toggle bankroll status
        bankrollStatus[_bankroll] = false;

        // set lpFee to 0
        lpFeeOf[_bankroll] = 0;
    }

    /**
     * @notice
     *  Update existing bankrolls fee
     *
     * @param _bankroll bankroll contract address to be blocked
     * @param _newFee bankroll contract address to be blocked
     *
     */
    function updateLpFee(address _bankroll, uint256 _newFee) external onlyRole(ADMIN) {
        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[_bankroll]) revert DGErrors.BANKROLL_NOT_APPROVED();

        // Check so that fee is withing range
        if (_newFee > DENOMINATOR) revert DGErrors.TO_HIGH_FEE();

        // set new LP fee
        lpFeeOf[_bankroll] = _newFee;
    }

    /**
     * @notice
     *  Allows admins to update eventperiods for bankrolls
     *  Oly calleable by admin role
     *
     * @param _bankroll address of the desired bankroll we want to update event period for
     * @param _eventPeriod the new updated event period
     *
     */
    function updateEventPeriod(address _bankroll, uint256 _eventPeriod) external onlyRole(ADMIN) {
        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[_bankroll]) revert DGErrors.BANKROLL_NOT_APPROVED();

        // Set new eventperiod
        eventPeriodOf[_bankroll] = _eventPeriod;
    }

    /**
     * @notice 
     *  Adding list of operator to list of operators associated with a bankroll
     *  Only calleable by admin role
     *
     * @param _bankroll the bankroll contract address
     * @param _operator address of the operator we want to add to the list of associated operators
     *
     */
    function setOperatorToBankroll(address _bankroll, address _operator) external onlyRole(ADMIN) {
        // Check so that operator isnt added to bankroll already
        if (operatorOfBankroll(_operator, _bankroll)) revert DGErrors.OPERATOR_ALREADY_ADDED_TO_BANKROLL();
        
        // Make sure that operator address is a wallet
        if (_isContract(_operator)) revert DGErrors.ADDRESS_NOT_A_WALLET();
        
        // Add operator into array of associated operators to bankroll
        operatorsOf[_bankroll].push(_operator);

        // Approve operator
        isApproved[_operator] = true;
    }

    /**
     * @notice
     *  Adding an operator to bankroll ecosystem
     *
     * @param _operator address of the operator
     *
     */
    function addOperator(address _operator) external onlyRole(ADMIN) {
        // Make sure that operator address is a wallet
        if (_isContract(_operator)) revert DGErrors.ADDRESS_NOT_A_WALLET();

        // Sett operators appoved status
        isApproved[_operator] = true;
    }

    /**
     * @notice
     *  Block an operator from all bankrolls
     *
     * @param _operator address of the operator we want to block
     *
     */
    function blockOperator(address _operator) external onlyRole(ADMIN) {
        // Remove operators approved status
        isApproved[_operator] = false;
    }

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
    function claimProfit(address _bankroll) external {
        // Check if eventperiod has passed
        if (block.timestamp < eventPeriodEnds[_bankroll]) revert DGErrors.EVENT_PERIOD_NOT_PASSED();

        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[_bankroll]) revert DGErrors.BANKROLL_NOT_APPROVED();
        
        // Fetch list of operators we will claim from
        address[] memory operators = operatorsOf[_bankroll];

        // Setup bankroll instance
        IBankroll bankroll = IBankroll(_bankroll);
        
        // Set up a token instance
        IERC20 token = IERC20(bankroll.viewTokenAddress());
        
        // Set up GGR for desired bankroll
        int256 GGR = bankroll.GGR();

        // Check if Casino GGR is posetive
        if (GGR < 1) revert DGErrors.NOTHING_TO_CLAIM();

        // Update event period ends unix timestamp to the eventperiod of specified bankroll
        eventPeriodEnds[_bankroll] = block.timestamp + eventPeriodOf[_bankroll];

        // variable for amount per operator
        uint256 amount;

        // variable for total amount
        uint256 totalAmount;

        // Loop over the operator list and perform the claim process over each operator
        for (uint256 i = 0; i < operators.length; i++) {
            if (bankroll.ggrOf(operators[i]) > 0) {
                // Amount to send
                amount += uint256(bankroll.ggrOf(operators[i])) - ((lpFeeOf[_bankroll] * uint256(bankroll.ggrOf(operators[i]))) / DENOMINATOR);

                // Increment total amount
                totalAmount += uint256(bankroll.ggrOf(operators[i]));

                // Zero out the GGR
                bankroll.nullGgrOf(operators[i]);
            }
        }

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // transfer the GGR to DeGaming
        token.safeTransferFrom(_bankroll, deGaming, amount);

        // fetch balance aftrer
        uint256 balanceAfter = token.balanceOf(address(this));

        // amount variable calculated from recieved balances
        uint256 realizedAmount = balanceAfter - balanceBefore;

        emit DGEvents.ProfitsClaimed(_bankroll, totalAmount, realizedAmount);
    }

    /**
     * @notice Check if a operator is associated to a bankroll
     *
     * @param _operator address of operator we want to check
     * @param _bankroll address of bankroll contract we want to check operator against
     *
     * @return _isRelated return a bool if operator is associated or not
     *
     */
    function operatorOfBankroll(address _operator, address _bankroll) public view returns (bool _isRelated) {
        // load an array of operators of bankroll
        address[] memory operatorList = operatorsOf[_bankroll];
        
        // If operator arg match any operator found in list, change _isRelated variable to true
        for (uint256 i; i < operatorList.length; i++) {
            if (operatorList[i] == _operator) {
                _isRelated = true;
            }
        }
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

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