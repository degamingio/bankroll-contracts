// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* Openzeppelin Interfaces */
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/* Openzeppelin Contracts */
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

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
contract DGBankrollManager is IDGBankrollManager, AccessControlUpgradeable {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev used to calculate percentages
    uint256 public constant DENOMINATOR = 10_000; 

    /// @dev DeGaming Wallet
    address public deGaming;

    /// @dev ADMIN role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev store bankroll status
    mapping(address bankroll => bool isApproved) public bankrollStatus;

    /// @dev store bankroll lp fees in percentage
    mapping(address bankroll => uint256 lpFee) public lpFeeOf;

    /// @dev mapping that stores all operators associated with a bankroll
    mapping(address bankroll => address[] operator) public operatorsOf;

    /// @dev mapping that if operator is approved
    mapping(address operator => bool approved) public isApproved;

    /// @dev Store a boolean if an operator s associated with a bankroll
    mapping(address bankroll => mapping(address operator => bool isAssociated)) public operatorOfBankroll;

    /// @dev Storage gap used for future upgrades (30 * 32 bytes)
    uint256[30] __gap;

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

    /**
     * @notice DGBankrollManager constructor
     *   Just sets the deployer of this contract as the owner
     *
     */ 
    function initialize(address _deGaming) external initializer {
        // Set DeGaming global variable
        deGaming = _deGaming;

        __AccessControl_init();

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
     *  Set new degaming address
     *  Only calleable by admin role
     *
     * @param _deGaming new degaming address
     *
     */
    function setDeGaming(address _deGaming) external onlyRole(ADMIN) {
        deGaming = _deGaming;
    }
    
    /**
     * @notice 
     *  Adding operator to list of operators associated with a bankroll
     *  Only calleable by admin role
     *
     * @param _bankroll the bankroll contract address
     * @param _operator address of the operator we want to add to the list of associated operators
     *
     */
    function setOperatorToBankroll(address _bankroll, address _operator) external onlyRole(ADMIN) {
        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[_bankroll]) revert DGErrors.BANKROLL_NOT_APPROVED();

        // Check so that operator isnt added to bankroll already
        if (operatorOfBankroll[_bankroll][_operator]) revert DGErrors.OPERATOR_ALREADY_ADDED_TO_BANKROLL();
        
        // Make sure that operator address is a wallet
        if (_isContract(_operator)) revert DGErrors.ADDRESS_NOT_A_WALLET();
        
        // Add operator into array of associated operators to bankroll
        operatorsOf[_bankroll].push(_operator);

        // Set operator of bankroll status to true
        operatorOfBankroll[_bankroll][_operator] = true;

        // Approve operator
        isApproved[_operator] = true;
    }

    /**
     * @notice 
     *  Remove operator from list of operators associated with a bankroll
     *  Only calleable by admin role
     *
     * @param _bankroll the bankroll contract address
     * @param _operator address of the operator we want to remove from the list of associated operators
     *
     */
    function removeOperatorFromBankroll(address _operator, address _bankroll) external onlyRole(ADMIN) {
        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[_bankroll]) revert DGErrors.BANKROLL_NOT_APPROVED();

        // Make sure that operator is associated with bankroll
        if (!operatorOfBankroll[_bankroll][_operator]) revert DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL();

        // fetch operators of bankroll
        address[] memory operators = operatorsOf[_bankroll];

        // Initiate operator intex
        uint256 operatorIndex = 0;

        // Search what index the operator has in the list of bankroll operators
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i] == _operator) {
                operatorIndex = i;
                break;
            }
        }

        // If operatorindex is the last one the switch around is not necessary
        if (operatorIndex != operators.length - 1) {
            // Replace the index of the operator with the last operator in the list
            operatorsOf[_bankroll][operatorIndex] = operatorsOf[_bankroll][operatorsOf[_bankroll].length - 1];
        }

        // Set operator of bankroll status to true
        operatorOfBankroll[_bankroll][_operator] = false;

        // Remove the last index in the list since this will now be a duplicate
        operatorsOf[_bankroll].pop();
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
    function claimProfit(address _bankroll) external onlyRole(ADMIN) {
        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[_bankroll]) revert DGErrors.BANKROLL_NOT_APPROVED();
        
        // Fetch list of operators we will claim from
        address[] memory operators = operatorsOf[_bankroll];

        // Setup bankroll instance
        IBankroll bankroll = IBankroll(_bankroll);
        
        // Set up a token instance
        IERC20Upgradeable token = IERC20Upgradeable(address(bankroll.token()));
        
        // Set up GGR for desired bankroll
        int256 GGR = bankroll.GGR();

        // Check if Casino GGR is posetive
        if (GGR < 10) revert DGErrors.NOTHING_TO_CLAIM();

        // variable for total amount
        uint256 totalAmount = 0;

        // Loop over the operator list and perform the claim process over each operator
        for (uint256 i = 0; i < operators.length; i++) {
            if (bankroll.ggrOf(operators[i]) > 0) {
                // Increment total amount
                totalAmount += uint256(bankroll.ggrOf(operators[i]));

                // Zero out the GGR
                bankroll.nullGgrOf(operators[i]);
            }
        }

        // Calculating the amount that should be transfered
        uint256 amountToTransfer = totalAmount - ((lpFeeOf[_bankroll] * totalAmount) / DENOMINATOR);

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // transfer the GGR to DeGaming
        token.safeTransferFrom(_bankroll, deGaming, amountToTransfer);

        // fetch balance aftrer
        uint256 balanceAfter = token.balanceOf(address(this));

        // amount variable calculated from recieved balances
        uint256 realizedAmount = balanceAfter - balanceBefore;

        // Emit event about claimed profits
        emit DGEvents.ProfitsClaimed(_bankroll, totalAmount, realizedAmount);
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
