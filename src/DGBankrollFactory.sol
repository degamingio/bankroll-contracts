// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Contract */
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/* DeGaming Contract */
import {Bankroll} from "src/Bankroll.sol";

/**
 * @title
 * @author DeGaming Technical Team
 * @notice Contract responsible for deploying DeGaming Bankrolls
 *
 */

contract DGBankrollFactory is AccessControl {
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
    address dgBankrollManager;

    /// @dev DeGaming admin account
    address public dgAdmin;

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

    function initialize(
        address _bankrollImpl,
        address _dgBankrollManager,
        address _dgAdmin
    ) external initializer {
        bankrollImpl = _bankrollImpl;
        dgBankrollManager = _dgBankrollManager;
        dgAdmin = _dgAdmin;

        __AccessControl_init();
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
     */
    function predictBankrollAddress(bytes32 _salt) external view returns (address _predicted) {
        _predicted = Clones.predictDeterministicAddress(bankrollImpl, _salt, address(this));
    }

}