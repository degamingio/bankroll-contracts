// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GameRoll {
   
    address public manager;
    uint256 public totalSupply;
    uint256 public constant DENOMINATOR = 10_000;
    IERC20 public immutable ERC20;
    mapping(address investor => uint256 deposited) public depositedOf;
    mapping(address investor => uint256 balance) public balanceOf;

    event FundsDeposited(uint256 amount);
    event FundsWithdrawn(uint256 amount);

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
        depositedOf[msg.sender] = depositedOf[msg.sender] + _amount;

        // transfer ERC20 from the user to the vault
        ERC20.transferFrom(msg.sender, address(this), _amount);

        emit FundsDeposited(_amount);
    }

     function withdrawAll() external onlyOwner {
        _withdraw(balanceOf[msg.sender]);
    }

    function setManager(address _manager) external {
        require(msg.sender == manager, "only manager can set manager");
        manager = _manager;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function getAmount(uint256 _shares) external view returns (uint256 _amount) {
        _amount = (_shares * ERC20.balanceOf(address(this))) / totalSupply;
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
        balanceOf[_to] += _shares;
    }

    function _burn(address _from, uint256 _shares) internal {
        // Decrement the total supply
        totalSupply -= _shares;

        // Decrement the share balance of the target
        balanceOf[_from] -= _shares;
    }

    function _withdraw(uint256 _shares) internal {
        // Calculate the amount of ERC20 worth of shares
        uint256 amount = (_shares * ERC20.balanceOf(address(this))) / totalSupply;

        // Burn the shares from the caller
        _burn(msg.sender, _shares);

        // Transfer ERC20 to the caller
        USDC.transfer(msg.sender, amount);

        // Zero investment tracking
        depositedOf[msg.sender] = 0;

        emit FundsWithdrawn(amount);
    }
}

