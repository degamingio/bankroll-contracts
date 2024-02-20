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

}