// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* Openzeppelin Interfaces */
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/* Openzeppelin Contracts */
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/* DeGaming Interfaces */
import {IBankroll} from "src/interfaces/IBankroll.sol";
import {IDGBankrollManager} from "src/interfaces/IDGBankrollManager.sol";
import {IDGEscrow} from "src/interfaces/IDGEscrow.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";

/**
 * @title Bankroll V2
 * @author DeGaming Technical Team
 * @notice Operator and Game Bankroll Contract
 *
 */
contract Bankroll is IBankroll, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev the current aggregated profit of the bankroll balance
    int256 public GGR;

    /// @dev total amount of shares
    uint256 public totalSupply;

    /// @dev used to calculate percentages
    uint256 public constant DENOMINATOR = 10_000; 

    /// @dev Max percentage of liquidity risked
    uint256 public maxRiskPercentage;

    /// @dev Escrow threshold absolute value
    uint256 public escrowTreshold;

    /// @dev amount for minimum pool in case it exists
    uint256 public minimumLp;

    // @dev Withdrawal delay
    uint256 public withdrawalDelay;

    /// @dev WithdrawalWindow length
    uint256 public withdrawalWindowLength;

    /// @dev Minimum time between withdrawal step one
    uint256 public withdrawalEventPeriod;

    /// @dev Minimum time between deposit and withdrawal
    uint256 public minimumDepositionTime;

    /// @dev ADMIN role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev BANKROLL_MANAGER role
    bytes32 public constant BANKROLL_MANAGER = keccak256("BANKROLL_MANAGER");

    /// @dev The GGR of a certain operator
    mapping(address operator => int256 operatorGGR) public ggrOf;

    /// @dev Withdrawal window per lp
    mapping(address lp => DGDataTypes.WithdrawalInfo info) withdrawalInfoOf;

    /// @dev Withdrawal stage one limit
    mapping(address lp => uint256 timestamp) public withdrawalLimitOf;

    /// @dev amount of shares per lp
    mapping(address lp => uint256 shares) public sharesOf; 

    /// @dev allowed LP addresses
    mapping(address lp => bool authorized) public lpWhitelist;

    /// @dev timestamp when an LP can withdraw
    mapping(address lp => uint256 withdrawable) public withdrawableTimeOf;

    /// @dev bankroll liquidity token
    IERC20Upgradeable public token;

    /// @dev Bankroll manager instance
    IDGBankrollManager dgBankrollManager; 

    /// @dev Escrow instance
    IDGEscrow escrow;

    /// @dev set status regarding if LP is open or whitelisted
    DGDataTypes.LpIs public lpIs = DGDataTypes.LpIs.OPEN;

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
        _mint(address(this), 1_000);
    }

    /**
     * @notice Bankroll constructor
     *
     * @param _admin Admin address
     * @param _token Bankroll liquidity token address
     * @param _bankrollManager address of bankroll manager
     * @param _escrow address of escrow contract
     * @param _owner address of contract owner
     * @param _maxRiskPercentage the max risk that the bankroll balance is risking for each game
     *
     */
    function initialize(
        address _admin,
        address _token,
        address _bankrollManager,
        address _escrow,
        address _owner,
        uint256 _maxRiskPercentage,
        uint256 _escrowThreshold
    ) external initializer {
        // Check so that both bankroll manager,token and escrow are contracts
        if (!_isContract(_bankrollManager) || !_isContract(_token) || !_isContract(_escrow)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Check so that owner is not a contract
        if (_isContract(_owner)) revert DGErrors.ADDRESS_NOT_A_WALLET();

        // Check so that maxRiskPercentage isnt larger than denominator
        if (_maxRiskPercentage > DENOMINATOR) revert DGErrors.MAXRISK_TOO_HIGH();

        // Initialize OZ packages
        __AccessControl_init();
        __ReentrancyGuard_init();

        // Initializing erc20 token associated with bankroll
        token = IERC20Upgradeable(_token);

        // Set the max risk percentage
        maxRiskPercentage = _maxRiskPercentage;

        // Set escrow threshold
        escrowTreshold = _escrowThreshold;

        // Set default withdrawal delay in seconds
        withdrawalDelay = 30;

        // Set default withdrawal window
        withdrawalWindowLength = 5 minutes;

        // Set default staging period
        withdrawalEventPeriod = 1 hours;

        // Set minimum deposition time
        minimumDepositionTime = 1 weeks;

        // Setup bankroll manager
        dgBankrollManager = IDGBankrollManager(_bankrollManager);

        // Setup escrow
        escrow = IDGEscrow(_escrow);

        // grant owner default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);

        // grant Admin role to escrow contract
        _grantRole(ADMIN, _escrow);

        // Grant Admin role
        _grantRole(ADMIN, _admin);

        // Grant Bankroll manager role
        _grantRole(BANKROLL_MANAGER, _bankrollManager);
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Deposit ERC20 tokens to the bankroll
     *  Called by Liquidity Providers
     *
     * @param _amount Amount of ERC20 tokens to deposit
     *
     */
    function depositFunds(uint256 _amount) external {
        // check if the user is allowed to deposit if the bankroll is not public
        if (
            lpIs == DGDataTypes.LpIs.WHITELISTED && 
            !lpWhitelist[msg.sender]
        ) revert DGErrors.LP_IS_NOT_WHITELISTED();

        // Check if the bankroll has a minimum lp and if so that the deposition exceeds it
        if (_amount < minimumLp) revert DGErrors.DEPOSITION_TO_LOW(); 

        // Set depositionLimit
        withdrawableTimeOf[msg.sender] = block.timestamp + minimumDepositionTime; 

        // store liquidity variable to calculate amounts of shares minted, since 
        // the liquidity() result will change before we have the amount variable
        uint256 liq = liquidity();

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // transfer ERC20 from the user to the vault
        token.safeTransferFrom(msg.sender, address(this), _amount);

        // fetch balance aftrer
        uint256 balanceAfter = token.balanceOf(address(this));

        // amount variable calculated from recieved balances
        uint256 amount = balanceAfter - balanceBefore;

        // // calculate the amount of shares to mint
        uint256 shares;
        if (totalSupply < 1 || totalSupply > 0 && liq == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply) / liq;
        }

        // mint shares to the user
        _mint(msg.sender, shares);

        // Emit a funds deposited event 
        emit DGEvents.FundsDeposited(msg.sender, amount);
    }

    /**
     * @notice Stage one of withdrawal process
     *
     * @param _amount Amount of shares to withdraw
     *
     */
    function withdrawalStageOne(uint256 _amount) external {
        // Make sure that LPs don't try to withdraw more than they have
        if (_amount > sharesOf[msg.sender]) revert DGErrors.LP_REQUESTED_AMOUNT_OVERFLOW();

        // Make sure that withdrawals are allowed
        if (withdrawalWindowLength == 0) revert DGErrors.WITHDRAWALS_NOT_ALLOWED();

        // Make sure that minimum deposition time has passed
        if (block.timestamp < withdrawableTimeOf[msg.sender]) revert DGErrors.MINIMUM_DEPOSITION_TIME_NOT_PASSED();

        // Fetch withdrawal info
        DGDataTypes.WithdrawalInfo memory withdrawalInfo = withdrawalInfoOf[msg.sender];

        // Make sure that previous withdrawal is either fullfilled or window has passed
        if (
            withdrawalInfo.stage == DGDataTypes.WithdrawalIs.STAGED &&
            block.timestamp < withdrawalInfo.timestamp + withdrawalWindowLength
        ) revert DGErrors.WITHDRAWAL_PROCESS_IN_STAGING();

        // Check so that event period timestamp has passed
        if (block.timestamp < withdrawalLimitOf[msg.sender]) revert DGErrors.WITHDRAWAL_TIMESTAMP_HASNT_PASSED();
        
        // Update withdrawalInfo of LP
        withdrawalInfoOf[msg.sender] = DGDataTypes.WithdrawalInfo(
            block.timestamp,
            _amount,
            DGDataTypes.WithdrawalIs.STAGED
        );

        // Set new withdrawal Limit of LP
        withdrawalLimitOf[msg.sender] = block.timestamp + withdrawalEventPeriod;

        // Emit withdrawal staged event
        emit DGEvents.WithdrawalStaged(msg.sender, block.timestamp + withdrawalDelay, block.timestamp + withdrawalWindowLength);
    }

    /**
     * @notice Stage two of withdrawal process
     *
     */
    function withdrawalStageTwo() external nonReentrant {
        // Fetch withdrawal info of sender
        DGDataTypes.WithdrawalInfo memory withdrawalInfo = withdrawalInfoOf[msg.sender];

        // make sure that withdrawal is in staging
        if (withdrawalInfo.stage == DGDataTypes.WithdrawalIs.FULLFILLED) revert DGErrors.WITHDRAWAL_ALREADY_FULLFILLED();

        // Make sure it is within withdrawal window
        if (
            block.timestamp < withdrawalInfo.timestamp + withdrawalDelay ||
            block.timestamp > withdrawalInfo.timestamp + withdrawalWindowLength
        ) revert DGErrors.OUTSIDE_WITHDRAWAL_WINDOW();

        // Call internal withdrawal function
        _withdraw(withdrawalInfo.amountToClaim, msg.sender);

        // Set stage status ti FULLFILLED
        withdrawalInfoOf[msg.sender].stage = DGDataTypes.WithdrawalIs.FULLFILLED;
    }

    /**
     * @notice Pay player amount in ERC20 tokens from the bankroll
     *  Called by Admin
     *
     * @param _player Player wallet
     * @param _amount Prize money amount
     * @param _operator The operator from which the call comes from
     *
     */
    function debit(address _player, uint256 _amount, address _operator) public onlyRole(ADMIN) {
        // Check that operator is approved
        if (!dgBankrollManager.isApproved(_operator)) revert DGErrors.NOT_AN_OPERATOR();

        // Check so that operator is associated with this bankroll
        if (!dgBankrollManager.operatorOfBankroll(address(this), _operator)) revert DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL();

        // pay what is left if amount is bigger than bankroll balance
        uint256 maxRisk = getMaxRisk();

        // Throw error if maxrisk is 0
        if (maxRisk == 0) revert DGErrors.MAX_RISK_ZERO();

        // Handle sweeping of bankroll
        if (_amount > maxRisk) {
            // Set maxRisk value to _amount variable
            _amount = maxRisk;

            // Emit event that the bankroll is sweppt
            emit DGEvents.BankrollSwept(_player, _amount);
        }

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // Create amount variable
        uint256 amount;

        // If amount is more then threshold, deposit into escrow...
        if (_amount > escrowTreshold) {
            escrow.depositFunds(_player, _operator, address(token), _amount);

            // fetch balance aftrer
            uint256 balanceAfter = token.balanceOf(address(this));

            // amount variable calculated from recieved balances
            amount = balanceBefore - balanceAfter;

        // ... Else go on with payout
        } else {

            // transfer ERC20 from the vault to the winner
            token.safeTransfer(_player, _amount);

            // fetch balance aftrer
            uint256 balanceAfter = token.balanceOf(address(this));

            // amount variable calculated from recieved balances
            amount = balanceBefore - balanceAfter;

            // Emit debit event
            emit DGEvents.Debit(msg.sender, _player, amount);
        }

        // substract from total GGR
        GGR -= int256(amount);
        
        // subtracting the amount from the specified operator GGR
        ggrOf[_operator] -= int256(amount);
    }

    /**
     * @notice Pay bankroll in ERC20 tokens from players loss
     *  Called by Admin
     *
     * @param _amount Player loss amount
     * @param _operator The operator from which the call comes from
     *
     */
    function credit(uint256 _amount, address _operator) public onlyRole(ADMIN) {
        // Check that operator is approved
        if (!dgBankrollManager.isApproved(_operator)) revert DGErrors.NOT_AN_OPERATOR();

        // Check so that operator is associated with this bankroll
        if (!dgBankrollManager.operatorOfBankroll(address(this), _operator)) revert DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL();

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // transfer ERC20 from the manager to the vault
        token.safeTransferFrom(msg.sender, address(this), _amount);
        
        // fetch balance aftrer
        uint256 balanceAfter = token.balanceOf(address(this));

        // amount variable calculated from recieved balances
        uint256 amount = balanceAfter - balanceBefore;

        // Add to total GGR
        GGR += int256(amount);

        // add the amount to the specified operator GGR
        ggrOf[_operator] += int256(amount);

        // Emit credit event
        emit DGEvents.Credit(msg.sender, amount);
    }


    /**
     * @notice Function for calling both the creditAndDebit function in order
     *  Called by Admin
     *
     * @param _creditAmount amount argument for credit function
     * @param _debitAmount amount argument for debit function
     * @param _operator The operator from which the call comes from
     * @param _player The player that should recieve the final payout
     *
     */
    function creditAndDebit(uint256 _creditAmount, uint256 _debitAmount, address _operator, address _player) external onlyRole(ADMIN) {
        // Credit function call
        credit(_creditAmount, _operator);

        // Debit function call
        debit(_player, _debitAmount, _operator);
    }

    /**
     * @notice Change withdrawal delay for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalDelay New withdrawal Delay in seconds
     *
     */
    function setWithdrawalDelay(uint256 _withdrawalDelay) external onlyRole(ADMIN) {
        if (_withdrawalDelay > withdrawalWindowLength) revert DGErrors.WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

        if (_withdrawalDelay < 30) revert DGErrors.WITHDRAWAL_DELAY_TO_SHORT();

        withdrawalDelay = _withdrawalDelay;
    }

    /**
     * @notice Change withdrawal window for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalWindow New withdrawal window in seconds
     *
     */
    function setWithdrawalWindow(uint256 _withdrawalWindow) external onlyRole(ADMIN) {
        if (_withdrawalWindow < withdrawalDelay) revert DGErrors.WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

        if (_withdrawalWindow > withdrawalEventPeriod) revert DGErrors.WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

        withdrawalWindowLength = _withdrawalWindow;
    }

    /**
     * @notice Change withdrawal (stage one) event period for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalEventPeriod New staging event period in seconds
     *
     */
    function setWithdrawalEventPeriod(uint256 _withdrawalEventPeriod) external onlyRole(ADMIN) {
        if (_withdrawalEventPeriod < withdrawalWindowLength) revert DGErrors.WITHDRAWAL_TIME_RANGE_NOT_ALLOWED();

        withdrawalEventPeriod = _withdrawalEventPeriod;
    }

    /**
     * @notice 
     *  Change the minumum time that has to pass between deposition and withdrawal
     *
     * @param _minimumDepositionTime new minimum deposition time in seconds
     *
     */
    function setMinimumDepositionTime(uint256 _minimumDepositionTime) external onlyRole(ADMIN) {
        minimumDepositionTime = _minimumDepositionTime;
    }


    /**
     * @notice
     *  Change an individual LPs withdrawable time for their deposition
     *
     * @param _timeStamp unix timestamp for when funds should get withdrawable
     * @param _LP Address of LP
     *
     */
    function setWithdrawableTimeOf(uint256 _timeStamp, address _LP) external onlyRole(ADMIN) {
        withdrawableTimeOf[_LP] = _timeStamp;
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

        // Revoke old bankroll manager role
        _revokeRole(BANKROLL_MANAGER, address(dgBankrollManager));

        // set the new bankroll manager
        dgBankrollManager = IDGBankrollManager(_newBankrollManager);

        // Grant new bankroll manager role
        _grantRole(BANKROLL_MANAGER, _newBankrollManager);
    }

    /**
     * @notice
     *  Setter for escrow contract
     *
     * @param _newEscrow address of new escrow
     *
     */
    function updateEscrow(address _newEscrow) external onlyRole(ADMIN) {
        // Make sure that new escrow address is a contract
        if (!_isContract(_newEscrow)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Set new escrow contract 
        escrow = IDGEscrow(_newEscrow);
    }

    /**
     * @notice Remove or add authorized liquidity provider to the bankroll
     *  Called by Admin
     *
     * @param _lp Liquidity Provider address
     * @param _isAuthorized If false, LP will not be able to deposit
     *
     */
    function setInvestorWhitelist(address _lp, bool _isAuthorized) external {
        // Check if caller is either an approved operator or admin wallet
        if (
            !dgBankrollManager.isApproved(msg.sender) &&
            !hasRole(ADMIN, msg.sender)
        ) revert DGErrors.NO_LP_ACCESS_PERMISSION();

        // Add toggle LPs _isAuthorized status
        lpWhitelist[_lp] = _isAuthorized;
    }

    /**
     * @notice Make bankroll permissionless for LPs or not
     *  Called by Admin
     *
     * @param _lpIs Toggle enum betwen OPEN and WHITELISTED
     *
     */
    function setPublic(DGDataTypes.LpIs _lpIs) external onlyRole(ADMIN) {
        // Toggle lpIs status
        lpIs = _lpIs;
    }

    /**
     * @notice Set the minimum LP amount for bankroll
     *  Called by Admin
     *
     * @param _amount Set tthe minimum lp amount
     *
     */
    function setMinimumLp(uint256 _amount) external onlyRole(ADMIN) {
        // set minimum lp
        minimumLp = _amount;
    }

    /**
     *
     * @notice allows admins to change the max risk amount
     *
     * @param _newAmount new amount in percentage that should be potentially risked per session 
     *
     */
    function changeMaxRisk(uint256 _newAmount) external onlyRole(ADMIN) {
        // Check so that maxrisk doestn't exceed 100%
        if (_newAmount > DENOMINATOR) revert DGErrors.MAXRISK_TOO_HIGH();

        // Set new maxrisk
        maxRiskPercentage = _newAmount;
    }

    /**
     *
     * @notice allows admins to change the max risk amount
     *
     * @param _newAmount new amount in that should be potentially risked per session
     *
     */
    function changeEscrowThreshold(uint256 _newAmount) external onlyRole(ADMIN) {
        // Set new maxrisk
        escrowTreshold = _newAmount;
    }

    /**
     * @notice Remove the GGR of a specified operator from the total GGR, 
     *  then null out the operator GGR. Only callable by the bankroll manager
     *
     * @param _operator the address  of the operator we want to null out
     *
     */
    function nullGgrOf(address _operator) external onlyRole(BANKROLL_MANAGER){
        // Subtract the GGR of the operator from the total GGR
        GGR -= ggrOf[_operator];

        // Null out operator GGR
        ggrOf[_operator] =  0;
    }

    /**
     *
     * @notice Max out the approval for the connected DeGaming contracts to spend on behalf of the bankroll contract
     *
     */
    function maxContractsApprove() external onlyRole(ADMIN) {
        // Approve bankroll manager address as a spender
        token.forceApprove(
            address(dgBankrollManager),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );

        // Approve escrow contract address as a spender
        token.forceApprove(
            address(escrow),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    } 

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Preview how much shares gets generated from _amount of tokens deposited
     *
     * @param _amount how many tokens should be checked
     *
     */
    function previewMint(uint256 _amount) public view returns(uint256 _shares) {
        // store liquidity variable to calculate amounts of shares minted, since 
        // the liquidity() result will change before we have the amount variable
        uint256 liq = liquidity();
        if (totalSupply < 1 || totalSupply > 0 && liq == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount * totalSupply) / liq;
        }
    }

    /**
     * @notice
     *  Check the value of x amount of shares
     *
     * @param _shares amount of shares to be checked
     *
     */
    function previewRedeem(uint256 _shares) public view returns(uint256 _amount) {
        _amount = (_shares * liquidity()) / totalSupply;
    }

    /**
     * @notice Returns the amount of ERC20 tokens held by the bankroll that are available for playes to win and
     *  will not include funds that are reserved for GGR
     *
     * @return _balance available balance for LPs
     *
     */
    function liquidity() public view returns (uint256 _balance) {
        if (GGR <= 0) {
            _balance = token.balanceOf(address(this));
        } else if (GGR > 0) {
            _balance = token.balanceOf(address(this)) - uint(GGR);
        }
    }

    /**
     * @notice Returns the current value of the LPs investment (deposit + profit).
     *
     * @param _lp Liquidity Provider address
     *
     * @return _amount the value of the lps holdings
     *
     */
    function getLpValue(address _lp) external view returns (uint256 _amount) {
        if (sharesOf[_lp] > 0) {
            _amount = (liquidity() * sharesOf[_lp]) / totalSupply;
        } else {
            _amount = 0;
        }
    }

    /**
     * @notice Returns the current stake of the LPs investment in percentage
     *
     * @param _lp Liquidity Provider address
     *
     * @return _stake the stake amount of given LP address
     *
     */
    function getLpStake(address _lp) external view returns (uint256 _stake) {
        if (sharesOf[_lp] > 0) {
            _stake = (sharesOf[_lp] * DENOMINATOR) / totalSupply;
        } else {
            _stake = 0;
        }
    }

    /**
     * @notice returns the maximum amount that can be taken from the bankroll during debit() call
     *
     * @return _maxRisk the maximum amount that can be risked
     *
     */
    function getMaxRisk() public view returns (uint256 _maxRisk) {
        _maxRisk = (liquidity() * maxRiskPercentage) / DENOMINATOR;
    }

    /**
     * @notice calculate percentages for the avalable liquidity, can be used to set the escrowThreshold
     *
     * @param _percentage percentage amount that should be calculated
     *
     * @return _amount absolute value calculated from the percentage of liquidity
     *
     */
    function calculateLiquidityPercentageAmount(uint256 _percentage) public view returns (uint256 _amount) {
        _amount = (liquidity() * _percentage) / DENOMINATOR;
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Mint shares to the caller
     *
     * @param _to Minted shares recipient
     * @param _shares Amount of shares to mint
     *
     */
    function _mint(address _to, uint256 _shares) internal {
        // Increment the total supply
        totalSupply += _shares;

        // Increment the share balance of the recipient
        sharesOf[_to] += _shares;
    }

    /**
     * @notice Burn shares from the caller
     *
     * @param _from Burner address
     * @param _shares Amount of shares to burn
     *
     */
    function _burn(address _from, uint256 _shares) internal {
        // Subtract from the total supply
        totalSupply -= _shares;

        // Subtract the share balance of the target
        sharesOf[_from] -= _shares;
    }

    /**
     * @notice Withdraw shares from the bankroll
     *
     * @param _shares Amount of shares to burn
     *
     */
    function _withdraw(uint256 _shares, address _reciever) internal {
        // Calculate the amount of ERC20 worth of shares
        uint256 amount = previewRedeem(_shares);

        // Burn the shares from the caller
        _burn(_reciever, _shares);

        // fetch balance before
        uint256 balanceBefore = token.balanceOf(address(this));

        // Transfer ERC20 to the caller
        token.safeTransfer(_reciever, amount);

        // fetch balance aftrer
        uint256 balanceAfter = token.balanceOf(address(this));

        // amount variable calculated from recieved balances
        uint256 realizedAmount = balanceBefore - balanceAfter;

        // Emit an event that funds are withdrawn
        emit DGEvents.FundsWithdrawn(_reciever, realizedAmount);
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
