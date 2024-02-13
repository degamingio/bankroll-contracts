// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBankroll} from "src/interfaces/IBankroll.sol";

import {DGErrors} from "src/libraries/DGErrors.sol";
import {DGEvents} from "src/libraries/DGEvents.sol";

/**
 * @title Bankroll V1
 * @author DeGaming Technical Team
 * @notice Operator and Game Bankroll Contract
 *
 */
contract Bankroll is IBankroll{
    //Using SafeERC20 for safer token interaction
    using SafeERC20 for IERC20;

    /// @dev admin address
    address public admin; 
    
    /// @dev total amount of shares
    uint256 public totalSupply; 
    
    /// @dev the current aggregated profit of the bankroll balance allocated for managers
    int256 public GGR; 
    
    ///  @dev the current aggregated profit of the bankroll balance allocated for lps
    int256 public lpsProfit;
    
    /// @dev total amount of ERC20 deposited by LPs
    uint256 public totalDeposit; 
    
    /// @dev used to calculate percentages
    uint256 public constant DENOMINATOR = 10_000; 
    
    /// @dev Max percentage of liquidity risked
    uint256 public maxRiskPercentage; 
    
    mapping(address operator => int256 operatorGGR) public ggrOf;
    
    /// @dev profit per manager
    mapping(address manager => int256 profit) public profitOf; 
    
    /// @dev managers that are allowed to operate this bankroll
    mapping(address manager => bool authorized) public managers; 
    
    /// @dev amount of shares per lp
    mapping(address lp => uint256 shares) public sharesOf; 
    
    /// @dev amount of ERC20 deposited per lp
    mapping(address lp => uint256 deposit) public depositOf; 
    
    /// @dev allowed LP addresses
    mapping(address lp => bool authorized) public lpWhitelist; 
    
    /// @dev bankroll liquidity token
    IERC20 public immutable ERC20; 
    
    /// @dev if false, only whitelisted lps can deposit
    bool public isPublic = true; 

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice Bankroll constructor
     * @param _admin Admin address
     * @param _ERC20 Bankroll liquidity token address
     */
    constructor(address _admin, address _ERC20, uint256 _maxRiskPercentage) {
        admin = _admin;
        ERC20 = IERC20(_ERC20);
        maxRiskPercentage = _maxRiskPercentage;
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Deposit ERC20 tokens to the bankroll
     * Called by Liquidity Providers
     * @param _amount Amount of ERC20 tokens to deposit
     */
    function depositFunds(uint256 _amount) external {
        // check if the user is allowed to deposit if the bankroll is not public
        if (!isPublic && !lpWhitelist[msg.sender]) revert DGErrors.LP_IS_NOT_WHITELISTED();

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

        emit DGEvents.FundsDeposited(msg.sender, _amount);
    }

    /**
     * @notice Withdraw all ERC20 tokens held by LP from the bankroll
     * Called by Liquidity Providers
     */
    function withdrawAll() external {
        // decrement total deposit
        totalDeposit -= depositOf[msg.sender];

        // decrement total LP profit
        lpsProfit -= getLpProfit(msg.sender);

        // zero lp deposit
        depositOf[msg.sender] = 0;

        _withdraw(sharesOf[msg.sender]);
    }

    /**
     * @notice Pay player amount in ERC20 tokens from the bankroll
     * Called by an authorized manager
     * @param _player Player wallet
     * @param _amount Prize money amount
     */
    function debit(address _player, uint256 _amount, address _operator) external {
        // check if caller is an authorized manager
        if (!managers[msg.sender]) revert DGErrors.SENDER_IS_NOT_A_MANAGER();

        // pay what is left if amount is bigger than bankroll balance
        uint256 maxRisk = getMaxRisk();
        if (_amount > maxRisk) {
            _amount = maxRisk;
            emit DGEvents.BankrollSwept(_player, _amount);
        }

        // substract from total managers profit
        // managersProfit -= int(_amount);
        GGR -= int256(_amount);
        ggrOf[_operator] -= int256(_amount);

        // substract from managers profit
        profitOf[msg.sender] -= int256(_amount);

        // transfer ERC20 from the vault to the winner
        //ERC20.transfer(_player, _amount);
        ERC20.safeTransfer(_player, _amount);

        emit DGEvents.Debit(msg.sender, _player, _amount);
    }

    /**
     * @notice Pay bankroll in ERC20 tokens from players loss
     * Called by an authorized manager
     * @param _amount Player loss amount
     */
    function credit(uint256 _amount, address _operator) external {
        // check if caller is an authorized manager
        if (!managers[msg.sender]) revert DGErrors.SENDER_IS_NOT_A_MANAGER();

        // add to total managers profit
        // managersProfit += int(_amount);
        GGR += int256(_amount);
        ggrOf[_operator] += int256(_amount);

        // add to managers profit
        profitOf[msg.sender] += int256(_amount);

        // transfer ERC20 from the manager to the vault
        ERC20.safeTransferFrom(msg.sender, address(this), _amount);

        emit DGEvents.Credit(msg.sender, _amount);
    }

    /**
     * @notice Remove or add authorized liquidity provider to the bankroll
     * Called by admin
     * @param _lp Liquidity Provider address
     * @param _isAuthorized If false, LP will not be able to deposit
     */
    function setInvestorWhitelist(address _lp, bool _isAuthorized) external {
        if (msg.sender != admin) revert DGErrors.SENDER_IS_NOT_AN_ADMIN();
        lpWhitelist[_lp] = _isAuthorized;
    }

    /**
     * @notice Set admin address
     * Called by admin
     * @param _admin Admin address
     */
    function setAdmin(address _admin) external {
        if (msg.sender != admin) revert DGErrors.SENDER_IS_NOT_AN_ADMIN();
        admin = _admin;
    }

    /**
     * @notice Remove or add authorized manager
     * Called by admin
     * @param _manager Manager address
     * @param isAuthorized If false, manager will not be able to operate the bankroll
     */
    function setManager(address _manager, bool isAuthorized) external {
        if (msg.sender != admin) revert DGErrors.SENDER_IS_NOT_AN_ADMIN();
        managers[_manager] = isAuthorized;
    }

    /**
     * @notice Make bankroll permissionless for LPs or not
     * Called by admin
     * @param _isPublic If false, only whitelisted lps can deposit
     */
    function setPublic(bool _isPublic) external {
        if (msg.sender != admin) revert DGErrors.SENDER_IS_NOT_AN_ADMIN();
        isPublic = _isPublic;
    }

    function nullGgrOf(address _operator) external {
        GGR -= ggrOf[_operator];
        ggrOf[_operator] =  0;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function viewTokenAddress() external view returns (address _token) {
        _token = address(ERC20);
    }

    /**
     * @notice Returns the amount of ERC20 tokens held by the bankroll that are available for playes to win and
     * will not include funds that are reserved for managers profit
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
     * @param _lp Liquidity Provider address
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
     * @param _lp Liquidity Provider address
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
     * @param _lp Liquidity Provider address
     */
    function getLpStake(address _lp) external view returns (uint256 _stake) {
        if (sharesOf[_lp] > 0) {
            _stake = (sharesOf[_lp] * DENOMINATOR) / totalSupply;
        } else {
            _stake = 0;
        }
    }

    function getMaxRisk() public view returns (uint256 _maxRisk) {
        uint256 currentLiquidity = liquidity();
        _maxRisk = (currentLiquidity * maxRiskPercentage) / DENOMINATOR;
    }

    //      ____      __                        __   ______                 __  _
    //     /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //     / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Mint shares to the caller
     * @param _to Minted shares recipient
     * @param _shares Amount of shares to mint
     */
    function _mint(address _to, uint256 _shares) internal {
        // Increment the total supply
        totalSupply += _shares;

        // Increment the share balance of the recipient
        sharesOf[_to] += _shares;
    }

    /**
     * @notice Burn shares from the caller
     * @param _from Burner address
     * @param _shares Amount of shares to burn
     */
    function _burn(address _from, uint256 _shares) internal {
        // Subtract from the total supply
        totalSupply -= _shares;

        // Subtract the share balance of the target
        sharesOf[_from] -= _shares;
    }

    /**
     * @notice Withdraw shares from the bankroll
     * @param _shares Amount of shares to burn
     */
    function _withdraw(uint256 _shares) internal {
        // Calculate the amount of ERC20 worth of shares
        uint256 amount = (_shares * liquidity()) / totalSupply;

        // Burn the shares from the caller
        _burn(msg.sender, _shares);

        // Transfer ERC20 to the caller
        ERC20.transfer(msg.sender, amount);

        emit DGEvents.FundsWithdrawn(msg.sender, amount);
    }
}
