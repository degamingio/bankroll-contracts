// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/* DeGaming Interfaces */
import {IBankroll} from "src/interfaces/IBankroll.sol";
import {IDGBankrollManager} from "src/interfaces/IDGBankrollManager.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGDataTypes} from "src/libraries/DGDataTypes.sol";

/**
 * @title Bankroll V1
 * @author DeGaming Technical Team
 * @notice Operator and Game Bankroll Contract
 *
 */
contract Bankroll is IBankroll, OwnableUpgradeable, AccessControlUpgradeable{
    /// @dev Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

    /// @dev total amount of shares
    uint256 public totalSupply; 
    
    /// @dev the current aggregated profit of the bankroll balance
    int256 public GGR; 
    
    /// @dev total amount of ERC20 deposited by LPs
    uint256 public totalDeposit; 
    
    /// @dev used to calculate percentages
    uint256 public constant DENOMINATOR = 10_000; 
    
    /// @dev Max percentage of liquidity risked
    uint256 public maxRiskPercentage; 
    
    /// @dev amount for minimum pool in case it exists
    uint256 public minimumLp;

    /// @dev Status regarding if bankroll has minimum for LPs to pool
    bool public hasMinimumLP = false;

    /// @dev ADMIN role
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev BANKROLL_MANAGER role
    bytes32 public constant BANKROLL_MANAGER = keccak256("BANKROLL_MANAGER");

    /// @dev The GGR of a certain operator
    mapping(address operator => int256 operatorGGR) public ggrOf;
    
    /// @dev profit per manager
    mapping(address manager => int256 profit) public profitOf; 
    
    /// @dev amount of shares per lp
    mapping(address lp => uint256 shares) public sharesOf; 
    
    /// @dev amount of ERC20 deposited per lp
    mapping(address lp => uint256 deposit) public depositOf; 
    
    /// @dev allowed LP addresses
    mapping(address lp => bool authorized) public lpWhitelist; 
    
    /// @dev bankroll liquidity token
    IERC20 public ERC20;

    /// @dev Bankroll manager instance
    IDGBankrollManager dgBankrollManager; 
    
    /// @dev set status regarding if LP is open or whitelisted
    DGDataTypes.LpIs public lpIs = DGDataTypes.LpIs.OPEN;

    /// @dev zero address, used for calling the universal event emitter when no second address is needed
    address constant NULL =  0x0000000000000000000000000000000000000000;

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
     * @notice Bankroll constructor
     *
     * @param _admin Admin address
     * @param _ERC20 Bankroll liquidity token address
     *
     */
    function initialize(
        address _admin,
        address _ERC20,
        address _bankrollManager,
        address _owner,
        uint256 _maxRiskPercentage
    ) external initializer {
        __AccessControl_init();

        __Ownable_init(_owner);

        // Initializing erc20 token associated with bankroll
        ERC20 = IERC20(_ERC20);

        // Set the max risk percentage
        maxRiskPercentage = _maxRiskPercentage;

        dgBankrollManager = IDGBankrollManager(_bankrollManager);

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
        if (
            hasMinimumLP &&
            _amount < minimumLp
        ) revert DGErrors.DEPOSITION_TO_LOW(); 

        // calculate the amount of shares to mint
        uint256 shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / liquidity();
        }

        // mint shares to the user
        _mint(msg.sender, shares);

        // track deposited amount
        depositOf[msg.sender] += _amount;

        // track total deposit amount
        totalDeposit += _amount;

        // transfer ERC20 from the user to the vault
        ERC20.safeTransferFrom(msg.sender, address(this), _amount);

        // Emit a funds deposited event 
        // (emit DGEvents.FundsDeposited(msg.sender, _amount))
        dgBankrollManager.emitEvent(
            DGDataTypes.EventSpecifier.FUNDS_DEPOSITED,
            msg.sender,
            NULL,
            _amount
        );
    }

    /**
     * @notice Withdraw all ERC20 tokens held by LP from the bankroll
     *  Called by Liquidity Providers
     *
     */
    function withdrawAll() external {
        // check if the user is allowed to deposit if the bankroll is not public
        if (
            lpIs == DGDataTypes.LpIs.WHITELISTED && 
            !lpWhitelist[msg.sender]
        ) revert DGErrors.LP_IS_NOT_WHITELISTED();
        
        // decrement total deposit
        totalDeposit -= depositOf[msg.sender];

        // zero lp deposit
        depositOf[msg.sender] = 0;

        // call internal withdrawal function
        _withdraw(sharesOf[msg.sender]);
    }


    /**
     * @notice Withdraw some ERC20 tokens held by LP from the bankroll
     *  Called by Liquidity Providers
     *
     * @param _amount how many shares that should be withdrawn
     *
     */
    function withdraw(uint256 _amount) external {
        // check if the user is allowed to deposit if the bankroll is not public
        if (
            lpIs == DGDataTypes.LpIs.WHITELISTED && 
            !lpWhitelist[msg.sender]
        ) revert DGErrors.LP_IS_NOT_WHITELISTED();

        // Check that the requested withdraw amount does not exceed the shares of
        if (_amount > sharesOf[msg.sender]) revert DGErrors.LP_REQUESTED_AMOUNT_OVERFLOW();

        // Calculate how many percentages of senders total shares they want to withdraw
        uint256 percentage = (_amount * DENOMINATOR) / sharesOf[msg.sender];

        // calculate what that same percentage is from that deposit of
        uint256 decrementFromDeposit = (depositOf[msg.sender] * percentage) / DENOMINATOR;

        // decrement total deposit
        totalDeposit -= decrementFromDeposit;

        // remove amount from deposit of 
        depositOf[msg.sender] -= decrementFromDeposit;

        // call internal withdrawal function
        _withdraw(_amount);
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
    function debit(address _player, uint256 _amount, address _operator) external onlyRole(ADMIN) {
        // Check that operator is approved
        if (!dgBankrollManager.isApproved(_operator)) revert DGErrors.NOT_AN_OPERATOR();
        
        // Check so that operator is associated with this bankroll
        if (!dgBankrollManager.operatorOfBankroll(_operator, address(this))) revert DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL();
        
        // pay what is left if amount is bigger than bankroll balance
        uint256 maxRisk = getMaxRisk();
        if (_amount > maxRisk) {
            _amount = maxRisk;
            // Emit event that the bankroll is sweppt
            //(emit DGEvents.BankrollSwept(_player, _amount))
            dgBankrollManager.emitEvent(
                DGDataTypes.EventSpecifier.BANKROLL_SWEPT,
                _player,
                NULL, 
                _amount
            );
        }

        // substract from total GGR
        GGR -= int256(_amount);
        
        // subtracting the amount from the specified operator GGR
        ggrOf[_operator] -= int256(_amount);

        // substract from operators profit
        profitOf[msg.sender] -= int256(_amount);

        // transfer ERC20 from the vault to the winner
        ERC20.safeTransfer(_player, _amount);

        // Emit debit event
        // (emit DGEvents.Debit(msg.sender, _player, _amount)
        dgBankrollManager.emitEvent(
            DGDataTypes.EventSpecifier.DEBIT,
            msg.sender,
            _player,
            _amount
        );
    }

    /**
     * @notice Pay bankroll in ERC20 tokens from players loss
     *  Called by Admin
     *
     * @param _amount Player loss amount
     * @param _operator The operator from which the call comes from
     *
     */
    function credit(uint256 _amount, address _operator) external onlyRole(ADMIN) {    
        // Check that operator is approved
        if (!dgBankrollManager.isApproved(_operator)) revert DGErrors.NOT_AN_OPERATOR();
        
        // Check so that operator is associated with this bankroll
        if (!dgBankrollManager.operatorOfBankroll(_operator, address(this))) revert DGErrors.OPERATOR_NOT_ASSOCIATED_WITH_BANKROLL();
        
        // Add to total GGR
        GGR += int256(_amount);
        
        // add the amount to the specified operator GGR
        ggrOf[_operator] += int256(_amount);

        // add to operators profit
        profitOf[msg.sender] += int256(_amount);

        // transfer ERC20 from the manager to the vault
        ERC20.safeTransferFrom(msg.sender, address(this), _amount);

        // Emit credit event
        // (emit DGEvents.Credit(msg.sender, _amount))
        dgBankrollManager.emitEvent(
            DGDataTypes.EventSpecifier.CREDIT,
            msg.sender,
            NULL,
            _amount
        );
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
     * @notice Set the minimum LP status for bankroll
     *  Called by Admin
     *
     * @param _status Toggle minimum lp status true or false
     *
     */
    function setMinimumLPStatus(bool _status) external onlyRole(ADMIN) {
        // toggle status of has minimum lp variable
        hasMinimumLP = _status;
    }

    /**
     * @notice Set the minimum LP amount for bankroll
     *  Called by Admin
     *
     * @param _amount Set tthe minimum lp amount
     *
     */
    function setMinimumLp(uint256 _amount) external onlyRole(ADMIN) {
        // toggle status  of minimum lp variable
        hasMinimumLP = true;

        // set minimum lp
        minimumLp = _amount;
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
     * @notice Update the ADMIN role
     *  Only calleable by contract owner
     *
     * @param _oldAdmin address of the old admin
     * @param _newAdmin address of the new admin
     *
     */
    function updateAdmin(address _oldAdmin, address _newAdmin) external onlyOwner {
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
    function updateBankrollManager(address _oldBankrollManager, address _newBankrollManager) external onlyOwner {
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

    /**
     *
     * @notice Max out the approval for DGBankrollManager.sol to spend on behalf of the bankroll contract
     *
     */
    function maxBankrollManagerApprove() external {
        ERC20.forceApprove(
            address(dgBankrollManager),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    } 

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Returns the adddress of the token associated with this bankroll
     *
     * @return _token token address
     *
     */
    function viewTokenAddress() external view returns (address _token) {
        _token = address(ERC20);
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
            _balance = ERC20.balanceOf(address(this));
        } else if (GGR > 0) {
            _balance = ERC20.balanceOf(address(this)) - uint(GGR);
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
     * @notice Returns the current profit of the LPs investment.
     *
     * @param _lp Liquidity Provider address
     *
     * @return _profit collected LP profit
     *
     */
    function getLpProfit(address _lp) public view returns (int256 _profit) {
        if (sharesOf[_lp] > 0) {
            _profit =
                ((int(liquidity()) * int(sharesOf[_lp])) / int(totalSupply)) -
                int(depositOf[_lp]);
        } else {
            _profit = 0;
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
        uint256 currentLiquidity = ERC20.balanceOf(address(this));
        _maxRisk = (currentLiquidity * maxRiskPercentage) / DENOMINATOR;
    }

    //      ____      __                        __   ______                 __  _
    //     /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //     / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

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
    function _withdraw(uint256 _shares) internal {
        // Calculate the amount of ERC20 worth of shares
        uint256 amount = (_shares * liquidity()) / totalSupply;

        // Burn the shares from the caller
        _burn(msg.sender, _shares);

        // Transfer ERC20 to the caller
        ERC20.transfer(msg.sender, amount);
    
        // Emit an event that funds are withdrawn
        // (emit DGEvents.FundsWithdrawn(msg.sender, amount))
        dgBankrollManager.emitEvent(
            DGDataTypes.EventSpecifier.FUNDS_WITHDRAWN,
            msg.sender,
            NULL,
            amount
        );
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
