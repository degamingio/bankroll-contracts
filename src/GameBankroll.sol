// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GameBankroll {
    address public manager;
    uint256 public totalSupply;
    uint256 public constant DENOMINATOR = 10_000;
    IERC20 public immutable ERC20;
    mapping(address investor => uint256 shares) public sharesOf;
    mapping(address investor => uint256 deposited) public depositedOf;

    event FundsDeposited(uint256 amount);
    event FundsWithdrawn(uint256 amount);
    event Debit(address player, uint256 amount);

    error FORBIDDEN();

    constructor(address _manager, address _ERC20) {
        manager = _manager;
        ERC20 = IERC20(_ERC20);
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function depositFunds(uint256 _amount) external {
        uint256 shares;

        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / ERC20.balanceOf(address(this));
        }

        // mint shares to the user
        _mint(msg.sender, shares);

        // track deposited amount
        depositedOf[msg.sender] += _amount;

        // transfer ERC20 from the user to the vault
        ERC20.transferFrom(msg.sender, address(this), _amount);

        emit FundsDeposited(_amount);
    }

    function withdrawAll() external {
        // Zero investment tracking
        depositedOf[msg.sender] = 0;

        _withdraw(sharesOf[msg.sender]);
    }

    function debit(address _player, uint256 _amount) external {
        if (msg.sender != manager) revert FORBIDDEN();

        // transfer ERC20 from the vault to the winner
        ERC20.transfer(_player, _amount);

        emit Debit(_player, _amount);
    }

    function setManager(address _manager) external {
        if (msg.sender != manager) revert FORBIDDEN();
        manager = _manager;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    //TODO: Reverts is no investmet
    function getAmount(
        address _investor
    ) external view returns (uint256 _amount) {
        uint256 _shares = sharesOf[_investor];
        _amount = _shares == 0
            ? 0
            : (_shares * ERC20.balanceOf(address(this))) / totalSupply;
    }

    //      ____      __                        __   ______                 __  _
    //     /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //     / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function _mint(address _to, uint256 _shares) internal {
        // Increment the total supply
        totalSupply += _shares;

        // Increment the share balance of the recipient
        sharesOf[_to] += _shares;
    }

    function _burn(address _from, uint256 _shares) internal {
        // Decrement the total supply
        totalSupply -= _shares;

        // Decrement the share balance of the target
        sharesOf[_from] -= _shares;
    }

    function _withdraw(uint256 _shares) internal {
        // Calculate the amount of ERC20 worth of shares
        uint256 amount = (_shares * ERC20.balanceOf(address(this))) /
            totalSupply;

        // Burn the shares from the caller
        _burn(msg.sender, _shares);

        // Transfer ERC20 to the caller
        ERC20.transfer(msg.sender, amount);

        emit FundsWithdrawn(amount);
    }
}
