// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/* DeGaming Contract */
import {Bankroll} from "src/Bankroll.sol";

/**
 * @title
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
     *
     */
    function initialize(
        address _bankrollImpl,
        address _dgBankrollManager,
        address _dgAdmin
    ) external initializer {

        // Initialize global variables
        bankrollImpl = _bankrollImpl;
        dgBankrollManager = _dgBankrollManager;
        dgAdmin = _dgAdmin;

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
     * @param _deGaming deGaming wallet address
     * @param _maxRiskPercentage max risk percentage in numbers (denominator 10_000 = 100)
     * @param _salt bytes used for deterministic deployment
     *
     */
    function deployBankroll(
        address _token,
        address _deGaming,
        uint256 _maxRiskPercentage,
        bytes32 _salt 
    ) external  onlyRole(DEFAULT_ADMIN_ROLE) {
        // Deploy new Bankroll contract
        Bankroll newBankroll = Bankroll(Clones.cloneDeterministic(bankrollImpl, _salt));

        // Initialize Bankroll contract
        newBankroll.initialize(
            dgAdmin,
            _token,
            dgBankrollManager,
            _deGaming,
            _maxRiskPercentage
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
        bankrollImpl = _newImpl;
    }

    /**
     * @notice
     *  Set DeGaming Bankroll Manager contract address
     *  Only the caller with role `DEFAULT_ADMIN_ROLE` can perform this operation
     *
     * @param _dgBankrollManager DeGaming admin account
     *
     */
    function setDgBankrollManager(address _dgBankrollManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dgBankrollManager = _dgBankrollManager;
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
}