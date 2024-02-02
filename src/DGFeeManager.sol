// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Openzeppelin Contracts */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";



contract DGFeeManager is Ownable {
    /// @dev basis points denominator used for percentage calculation
    uint256 public constant DENOMINATOR = 10_000;

    /// @dev Event period, the minimum time between each claim
    uint256 public constant EVENT_PERIOD = 30 days;

    mapping(address bankroll => bool isApproved) public bankrollStatus;

}