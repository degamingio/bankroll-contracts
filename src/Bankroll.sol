// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bankroll {
    address public admin; // admin address
    uint256 public totalSupply; // total amount of shares
    uint256 public constant DENOMINATOR = 10_000;
    IERC20 public immutable ERC20; // bankroll liquidity token
    mapping(address manager => bool authorized) public managers; // managers that are allowed to operate this bankroll
    mapping(address investor => uint256 shares) public sharesOf; // amount of shares per investor
    mapping(address investor => uint256 investment) public investmentOf; // amount of ERC20 deposited per investor
    mapping(address investor => bool authorized) public investorWhitelist; // allowed addresses to deposit
    bool public isPublic = true; // if false, only whitelisted investors can deposit

    event FundsDeposited(uint256 amount);
    event FundsWithdrawn(uint256 amount);
    event Debit(address player, uint256 amount);
    event Credit(uint256 amount);
    event RevenueClaimed(address manager, uint256 amount);

    error FORBIDDEN();

    constructor(address _admin, address _ERC20) {
        admin = _admin;
        ERC20 = IERC20(_ERC20);
    }

    //      ______     __                        __   ______                 __  _
    //     / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //   / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function depositFunds(uint256 _amount) external {
        // check if the user is allowed to deposit if the bankroll is not public
        if (!isPublic && !investorWhitelist[msg.sender]) revert FORBIDDEN();

        uint256 shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / ERC20.balanceOf(address(this));
        }

        // mint shares to the user
        _mint(msg.sender, shares);

        // track deposited amount
        investmentOf[msg.sender] += _amount;

        // transfer ERC20 from the user to the vault
        ERC20.transferFrom(msg.sender, address(this), _amount);

        emit FundsDeposited(_amount);
    }

    function withdrawAll() external {
        // Zero investment tracking
        investmentOf[msg.sender] = 0;

        _withdraw(sharesOf[msg.sender]);
    }

    function debit(address _player, uint256 _amount) external {
        if (!managers[msg.sender]) revert FORBIDDEN();

        // pay what is left if amount is bigger than amount
        uint256 balance = ERC20.balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }
        // transfer ERC20 from the vault to the winner
        ERC20.transfer(_player, _amount);

        emit Debit(_player, _amount);
    }

    function credit(uint256 _amount) external {
        if (!managers[msg.sender]) revert FORBIDDEN();

        //TODO: increment a global revenue counter

        // transfer ERC20 from the manager to the vault
        ERC20.transferFrom(msg.sender, address(this), _amount);

        emit Credit(_amount);
    }

    function claimRevenue(uint256 _amount) external {
        if (!managers[msg.sender]) revert FORBIDDEN();

        // transfer ERC20 from the vault to the manager
        ERC20.transfer(msg.sender, _amount);

        emit RevenueClaimed(msg.sender, _amount);
    }

    function setInvestorWhitelist(
        address _investor,
        bool _isAuthorized
    ) external {
        if (msg.sender != admin) revert FORBIDDEN();
        investorWhitelist[_investor] = _isAuthorized;
    }

    function setAdmin(address _admin) external {
        if (msg.sender != admin) revert FORBIDDEN();
        admin = _admin;
    }

    function setManager(address _manager, bool isAuthorized) external {
        if (msg.sender != admin) revert FORBIDDEN();
        managers[_manager] = isAuthorized;
    }

    function setPublic(bool _isPublic) external {
        if (msg.sender != admin) revert FORBIDDEN();
        isPublic = _isPublic;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function getInvestorAvailableAmount(
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
    //   / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
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
