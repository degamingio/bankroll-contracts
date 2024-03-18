// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/* Openzeppelin Contract */
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/* DeGaming Contract */
import {Bankroll} from "src/Bankroll.sol";

/* DeGaming Libraries */
import {DGErrors} from "src/libraries/DGErrors.sol";

/**
 * @title  DGBankrollFactory
 * @author DeGaming Technical Team
 * @notice Contract responsible for deploying DeGaming Bankrolls
 *
 */
contract DGBankrollFactory is AccessControlUpgradeable {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev number of collection created by this factory
    uint256 public bankrollCount;

    /// @dev Array of all Bankrolls created by this factory
    address[] public bankrolls;

    /// @dev Standard DeGaming Bankroll contract implementation address
    address public bankrollImpl;

    /// @dev DeGaming Bankroll Manager Contract address
    address public dgBankrollManager;

    /// @dev DeGaming Escrow contract address
    address public escrow;

    /// @dev DeGaming admin account
    address public dgAdmin;

    /// @dev DeGaming address
    address public deGaming;

    /// @dev Storage gap used for future upgrades (30 * 32 bytes)
    uint256[30] __gap;

    //    ______                 __                  __
    //   / ____/___  ____  _____/ /________  _______/ /_____  _____
    //  / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    // / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    // \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Constructor
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice
     *  Contract Initializer
     *
     * @param _bankrollImpl address of DeGaming implementation of Bankroll contract
     * @param _dgBankrollManager DeGaming bankroll manager  contract address
     * @param _dgAdmin DeGaming admin account
     * @param _deGaming DeGaming wallet
     *
     */
    function initialize(
        address _bankrollImpl,
        address _dgBankrollManager,
        address _escrow,
        address _dgAdmin,
        address _deGaming
    ) external initializer {
        // Initialize global variables
        bankrollImpl = _bankrollImpl;
        dgBankrollManager = _dgBankrollManager;
        escrow = _escrow;
        dgAdmin = _dgAdmin;
        deGaming = _deGaming;

        // initialize access controll
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * @notice
     *  Deploy a new Bankroll instance
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _token address of token asociated with bankroll
     * @param _maxRiskPercentage max risk percentage in numbers (denominator 10_000 = 100)
     * @param _salt bytes used for deterministic deployment
     *
     */
    function deployBankroll(
        address _token,
        uint256 _maxRiskPercentage,
        uint256 _escrowThreshold,
        bytes32 _salt 
    ) external  onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that token address is a contract
        if (!_isContract(_token)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Make sure that maxrisk does not exceed 100%
        if (_maxRiskPercentage > 10_000) revert DGErrors.MAXRISK_TOO_HIGH();

        // Deploy new Bankroll contract
        Bankroll newBankroll = Bankroll(Clones.cloneDeterministic(bankrollImpl, _salt));

        // Initialize Bankroll contract
        newBankroll.initialize(
            dgAdmin,
            _token,
            dgBankrollManager,
            escrow,
            deGaming,
            _maxRiskPercentage,
            _escrowThreshold
        );

        // Add address to list of bankrolls
        bankrolls.push(address(newBankroll));
        
        // Increment bankroll counter
        ++bankrollCount;
    }

    /**
     * @notice
     *  Set Bankroll implementation address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _newImpl address of the new implementation contract
     *
     */
    function setBankrollImplementation(address _newImpl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that new bankroll implementation is a contract
        if (!_isContract(_newImpl)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // set new bankroll implementation
        bankrollImpl = _newImpl;
    }

    /**
     * @notice
     *  Set DeGaming Bankroll Manager contract address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dgBankrollManager Bankroll Manager Contract address
     *
     */
    function setDgBankrollManager(address _dgBankrollManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that new bankroll manager is a contract
        if (!_isContract(_dgBankrollManager)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Set new bankroll manager
        dgBankrollManager = _dgBankrollManager;
    }

    /**
     * @notice
     *  Set DeGaming Escrow contract address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _escrow Escrow Contract address
     *
     */
    function setDgEscrow(address _escrow) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Make sure that new escrow address is a contract
        if (!_isContract(_escrow)) revert DGErrors.ADDRESS_NOT_A_CONTRACT();

        // Set new escrow address
        escrow = _escrow;
    }

    /**
     * @notice
     *  Set DeGaming admin account
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dgAdmin DeGaming admin account
     *
     */
    function setDgAdmin(address _dgAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dgAdmin = _dgAdmin;
    }

    /**
     * @notice
     *  Set DeGaming wallet address 
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _deGaming DeGaming wallet
     *
     */
    function setDeGaming(address _deGaming) external onlyRole(DEFAULT_ADMIN_ROLE) {
        deGaming = _deGaming;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Predict the new Bankroll contract address
     *
     * @param _salt salt used for the deterministic deployment
     *
     * @return _predicted predicted address for the given `_salt`
     *
     */
    function predictBankrollAddress(bytes32 _salt) external view returns (address _predicted) {
        _predicted = Clones.predictDeterministicAddress(bankrollImpl, _salt, address(this));
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