// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IBankroll V1
 * @author DeGaming Technical Team
 * @notice Interface for Bankroll kontract
 *
 */
interface IBankroll { 
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
    function depositFunds(uint256 _amount) external;

    /**
     * @notice Withdraw all ERC20 tokens held by LP from the bankroll
     * Called by Liquidity Providers
     */
    function withdrawAll() external;

    /**
     * @notice Pay player amount in ERC20 tokens from the bankroll
     * Called by an authorized manager
     * @param _player Player wallet
     * @param _amount Prize money amount
     */
    function debit(address _player, uint256 _amount, address _operator) external;

    /**
     * @notice Pay bankroll in ERC20 tokens from players loss
     * Called by an authorized manager
     * @param _amount Player loss amount
     */
    function credit(uint256 _amount, address _operator) external;
    
    /**
     * @notice Remove or add authorized liquidity provider to the bankroll
     * Called by admin
     * @param _lp Liquidity Provider address
     * @param _isAuthorized If false, LP will not be able to deposit
     */
    function setInvestorWhitelist(address _lp, bool _isAuthorized) external;

    /**
     * @notice Set admin address
     * Called by admin
     * @param _admin Admin address
     */
    function setAdmin(address _admin) external; 

    /**
     * @notice Remove or add authorized manager
     * Called by admin
     * @param _manager Manager address
     * @param isAuthorized If false, manager will not be able to operate the bankroll
     */
    function setManager(address _manager, bool isAuthorized) external;

    /**
     * @notice Make bankroll permissionless for LPs or not
     * Called by admin
     * @param _isPublic If false, only whitelisted lps can deposit
     */
    function setPublic(bool _isPublic) external;

    function nullGgrOf(address _operator) external;

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice Returns the amount of ERC20 tokens held by the bankroll that are available for playes to win and
     * will not include funds that are reserved for managers profit
     */
    function liquidity() external view returns (uint256 _balance); 

    /**
     * @notice Returns the current value of the LPs investment (deposit + profit).
     * @param _lp Liquidity Provider address
     */
    function getLpValue(address _lp) external view returns (uint256 _amount);

    /**
     * @notice Returns the current profit of the LPs investment.
     * @param _lp Liquidity Provider address
     */
    function getLpProfit(address _lp) external view returns (int256 _profit);

    /**
     * @notice Returns the current stake of the LPs investment in percentage
     * @param _lp Liquidity Provider address
     */
    function getLpStake(address _lp) external view returns (uint256 _stake);

    function getMaxRisk() external view returns (uint256 _maxRisk);

    function GGR() external view returns(int256);

    function ggrOf(address _operator) external view returns(int256 _operatorGgr);

    //function ERC20() external view returns(address);
}
