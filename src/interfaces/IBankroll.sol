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
     *  Called by Liquidity Providers
     *
     * @param _amount Amount of ERC20 tokens to deposit
     *
     */
    function depositFunds(uint256 _amount) external;

    /**
     * @notice Withdraw all ERC20 tokens held by LP from the bankroll
     *  Called by Liquidity Providers
     *
     */
    function withdrawAll() external;

    /**
     * @notice Pay player amount in ERC20 tokens from the bankroll
     *  Called by Admin
     *
     * @param _player Player wallet
     * @param _amount Prize money amount
     * @param _operator The operator from which the call comes from
     *
     */
    function debit(address _player, uint256 _amount, address _operator) external;

    /**
     * @notice Pay bankroll in ERC20 tokens from players loss
     *  Called by Admin
     *
     * @param _amount Player loss amount
     * @param _operator The operator from which the call comes from
     *
     */
    function credit(uint256 _amount, address _operator) external;

    /**
     * @notice Remove or add authorized liquidity provider to the bankroll
     *  Called by Admin
     *
     * @param _lp Liquidity Provider address
     * @param _isAuthorized If false, LP will not be able to deposit
     *
     */
    function setInvestorWhitelist(address _lp, bool _isAuthorized) external;

    /**
     * @notice Make bankroll permissionless for LPs or not
     *  Called by Admin
     *
     * @param _isPublic If false, only whitelisted lps can deposit
     *
     */
    function setPublic(bool _isPublic) external;

    /**
     * @notice Remove the GGR of a specified operator from the total GGR, 
     *  then null out the operator GGR. Only callable by the bankroll manager
     *
     * @param _operator the address  of the operator we want to null out
     *
     */
    function nullGgrOf(address _operator) external;

    /**
     * @notice Update the ADMIN role
     *  Only calleable by contract owner
     *
     * @param _oldAdmin address of the old admin
     * @param _newAdmin address of the new admin
     *
     */
    function updateAdmin(address _oldAdmin, address _newAdmin) external;

    /**
     * @notice Update the BANKROLL_MANAGER role
     *  Only calleable by contract owner
     *
     * @param _oldBankrollManager address of the old bankroll manager
     * @param _newBankrollManager address of the new bankroll manager
     *
     */
    function updateBankrollManager(address _oldBankrollManager, address _newBankrollManager) external;

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
    function viewTokenAddress() external view returns (address _token);

    /**
     * @notice Returns the amount of ERC20 tokens held by the bankroll that are available for playes to win and
     *  will not include funds that are reserved for GGR
     *
     * @return _balance available balance for LPs
     *
     */
    function liquidity() external view returns (uint256 _balance);

    /**
     * @notice Returns the current value of the LPs investment (deposit + profit).
     *
     * @param _lp Liquidity Provider address
     *
     * @return _amount the value of the lps holdings
     *
     */
    function getLpValue(address _lp) external view returns (uint256 _amount);

    /**
     * @notice Returns the current profit of the LPs investment.
     *
     * @param _lp Liquidity Provider address
     *
     * @return _profit collected LP profit
     *
     */
    function getLpProfit(address _lp) external view returns (int256 _profit);

    /**
     * @notice Returns the current stake of the LPs investment in percentage
     *
     * @param _lp Liquidity Provider address
     *
     * @return _stake the stake amount of given LP address
     *
     */
    function getLpStake(address _lp) external view returns (uint256 _stake);

    /**
     * @notice returns the maximum amount that can be taken from the bankroll during debit() call
     *
     * @return _maxRisk the maximum amount that can be risked
     *
     */
    function getMaxRisk() external view returns (uint256 _maxRisk);

    /**
     * @notice Getter function for GGR variable
     *
     */
    function GGR() external view returns(int256);

    /**
     * @notice getter function for ggrOf mapping
     *
     * @param operator address of operator
     *
     * @return operatorGGR the GGR of specified operator
     *
     */
    function ggrOf(address operator) external view returns(int256 operatorGGR);
}
