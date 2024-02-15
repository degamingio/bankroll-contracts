// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
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

/**
 * @title DGBankrollManager
 * @author DeGaming Technical Team
 * @notice Fee management of GGR 
 *
 */
contract DGBankrollManager is IDGBankrollManager, Ownable, AccessControl {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

    /// @dev Event period, the minimum time between each claim
    uint256 public constant EVENT_PERIOD = 30 days;

    /// @dev used to calculate percentages
    uint256 public constant DENOMINATOR = 10_000; 

    /// @dev DeGaming Wallet
    address deGaming;

    /// @dev Set up bankroll instance
    IBankroll bankroll;

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
    constructor(address _deGaming) Ownable(msg.sender) {
        deGaming = _deGaming;
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
     *  Only the contract owner can execute this operation
     *
     * @param _bankroll bankroll contract address to be approved
     *
     */
    function approveBankroll(address _bankroll, uint256 _fee) external onlyOwner {
        // Toggle bankroll status
        bankrollStatus[_bankroll] = true;

        // set LP fee
        lpFeeOf[_bankroll] = _fee;
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

        // set lpFee to 0
        lpFeeOf[_bankroll] = 0;
    }

    /**
     * @notice 
     *  Adding list of operator to list of operators associated with a bankroll
     *  Only calleable by owner
     *
     * @param _bankroll the bankroll contract address
     * @param _operator address of the operator we want to add to the list of associated operators
     *
     */
    function setOperatorToBankroll(address _bankroll, address _operator) external onlyOwner {
        // Add operator into array of associated operators to bankroll
        operatorsOf[_bankroll].push(_operator);

        // Approve operator
        isApproved[_operator] = true;
    }

    /**
     * @notice
     *  Adding an operator to bankroll ecosystem
     *
     * @param _operator address of the operaotr
     *
     */
    function addOperator(address _operator) external onlyRole(ADMIN) {
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
        bankroll = IBankroll(_bankroll);
        
        // Set up a token instance
        IERC20 token = IERC20(bankroll.viewTokenAddress());
        
        // Set up GGR for desired bankroll
        int256 GGR = bankroll.GGR();

        // Check if Casino GGR is posetive
        if (GGR < 1) revert DGErrors.NOTHING_TO_CLAIM();

        // Update event period ends unix timestamp to one <EVENT_PERIOD> from now
        eventPeriodEnds[_bankroll] = block.timestamp + EVENT_PERIOD;

        uint256 amount;

        uint256 totalAmount;

        // Loop over the operator list and perform the claim process over each operator
        for (uint256 i = 0; i < operators.length; i++) {
            if (bankroll.ggrOf(operators[i]) > 0) {
                // Amount to send
                amount = uint256(bankroll.ggrOf(operators[i])) - ((lpFeeOf[_bankroll] * uint256(bankroll.ggrOf(operators[i]))) / DENOMINATOR);

                // transfer the GGR to DeGaming
                token.safeTransferFrom(
                    _bankroll, 
                    deGaming, 
                    amount
                );

                totalAmount += bankroll.ggrOf(operators[i]);

                // Zero out the GGR
                bankroll.nullGgrOf(operators[i]);
            }
        }

        DGEvents.ProfitsClaimed(_bankroll, totalAmount);
    }


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
        uint256 _eventSpecifier,
        address _address1,
        address _address2,
        uint256 _number
    ) external {
        // Check that the bankroll is an approved DeGaming Bankroll
        if (!bankrollStatus[msg.sender]) revert DGErrors.BANKROLL_NOT_APPROVED();
        
        // Chose what event to emit
        if (_eventSpecifier == 0) {
            emit DGEvents.FundsDeposited(msg.sender, _address1, _number);
        } else if (_eventSpecifier == 1) {
            emit DGEvents.FundsWithdrawn(msg.sender, _address1, _number);
        } else if (_eventSpecifier == 2) {
            emit DGEvents.Debit(msg.sender, _address1, _address2, _number);
        } else if (_eventSpecifier == 3) {
            emit DGEvents.Credit(msg.sender, _address1, _number);
        } else if (_eventSpecifier == 4) {
            emit DGEvents.BankrollSwept(msg.sender, _address1, _number);
        }
    }
}