// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DGDataTypes} from "src/libraries/DGDataTypes.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IBankroll V2
 * @author DeGaming Technical Team
 * @notice Interface for Bankroll contract
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
     * @notice Stage one of withdrawal process
     *
     * @param _amount Amount of shares to withdraw
     *
     */
    function withdrawalStageOne(uint256 _amount) external;

    /**
     * @notice Stage two of withdrawal process
     *
     */
    function withdrawalStageTwo() external;

    /**
     * @notice Change withdrawal delay for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalDelay New withdrawal Delay in seconds
     *
     */
    function setWithdrawalDelay(uint256 _withdrawalDelay) external;

    /**
     * @notice Change withdrawal window for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalWindow New withdrawal window in seconds
     *
     */
    function setWithdrawalWindow(uint256 _withdrawalWindow) external;

    /**
     * @notice 
     *  Change the minumum time that has to pass between deposition and withdrawal
     *
     * @param _minimumDepositionTime new minimum deposition time in seconds
     *
     */
    function setMinimumDepositionTime(uint256 _minimumDepositionTime) external;

    /**
     * @notice
     *  Change an individual LPs withdrawable time for their deposition
     *
     * @param _timeStamp unix timestamp for when funds should get withdrawable
     * @param _LP Address of LP
     *
     */
    function setWithdrawableTimeOf(uint256 _timeStamp, address _LP) external;

    /**
     * @notice
     *  Allows admin to update bankroll manager contract
     *
     * @param _newBankrollManager address of the new bankroll manager
     *
     */
    function updateBankrollManager(address _newBankrollManager) external;

    /**
     * @notice Change staging event period for LPs
     *  Only callable by ADMIN
     *
     * @param _withdrawalEventPeriod New staging event period in seconds
     *
     */
    function setWithdrawalEventPeriod(uint256 _withdrawalEventPeriod) external;

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
     * @notice Function for calling both the creditAndDebit function in order
     *  Called by Admin
     *
     * @param _creditAmount amount argument for credit function
     * @param _debitAmount amount argument for debit function
     * @param _operator The operator from which the call comes from
     * @param _player The player that should recieve the final payout
     *
     */
    function creditAndDebit(uint256 _creditAmount, uint256 _debitAmount, address _operator, address _player) external;

    /**
     * @notice
     *  Setter for escrow contract
     *
     * @param _newEscrow address of new escrow
     *
     */
    function updateEscrow(address _newEscrow) external;

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
     * @param _lpIs Toggle enum betwen OPEN and WHITELISTED
     *
     */
    function setPublic(DGDataTypes.LpIs _lpIs) external;

    /**
     * @notice Remove the GGR of a specified operator from the total GGR, 
     *  then null out the operator GGR. Only callable by the bankroll manager
     *
     * @param _operator the address  of the operator we want to null out
     *
     */
    function nullGgrOf(address _operator) external;

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
    function previewMint(uint256 _amount) external view returns(uint256 _shares);

    /**
     * @notice
     *  Check the value of x amount of shares
     *
     * @param _shares amount of shares to be checked
     *
     */
    function previewRedeem(uint256 _shares) external view returns(uint256 _amount);

    function token() external view returns (IERC20Upgradeable token);

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
