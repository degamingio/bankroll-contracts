// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Openzeppelin Interfaces */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Bankroll {
    uint16 public lpFee = 650; // 6.5% bankroll lpFee of profit
    address public admin; // admin address
    uint256 public totalSupply; // total amount of shares
    int256 public managersProfit; // the total profit of the bankroll allocated for managers and LPs
    int256 public lpsProfit;
    uint256 public totalDeposit;
    uint256 public constant DENOMINATOR = 10_000;
    mapping(address manager => int256 profit) public profitOf; // profit per manager
    mapping(address manager => bool authorized) public managers; // managers that are allowed to operate this bankroll
    mapping(address investor => uint256 shares) public sharesOf; // amount of shares per investor
    mapping(address investor => uint256 deposit) public depositOf; // amount of ERC20 deposited per investor
    mapping(address investor => bool authorized) public investorWhitelist; // allowed addresses to deposit
    IERC20 public immutable ERC20; // bankroll liquidity token
    bool public isPublic = true; // if false, only whitelisted investors can deposit

    // events
    event FundsDeposited(address investor, uint256 amount);
    event FundsWithdrawn(address investor, uint256 amount);
    event Debit(address manager, address player, uint256 amount);
    event Credit(address manager, uint256 amount);
    event ProfitClaimed(address manager, uint256 amount);
    event BankrollSwept(address player, uint256 amount);

    // errors
    error FORBIDDEN();
    error NO_PROFIT();

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
            shares = (_amount * totalSupply) / liquidity();
        }

        // mint shares to the user
        _mint(msg.sender, shares);

        // track deposited amount
        depositOf[msg.sender] += _amount;

        // track total deposit
        totalDeposit += _amount;

        // transfer ERC20 from the user to the vault
        ERC20.transferFrom(msg.sender, address(this), _amount);

        emit FundsDeposited(msg.sender, _amount);
    }

    function withdrawAll() external {
        // Remove the initial deposit from total deposit
        totalDeposit -= depositOf[msg.sender];

        int256 investorProfit = getInvestorProfit(msg.sender);

        lpsProfit -= investorProfit;

        // Zero investment tracking
        depositOf[msg.sender] = 0;

        _withdraw(sharesOf[msg.sender], msg.sender);
    }

    function debit(address _player, uint256 _amount) external {
        if (!managers[msg.sender]) revert FORBIDDEN();

        // pay what is left if amount is bigger than bankroll balance
        uint256 _balance = liquidity();
        if (_amount > _balance) {
            _amount = _balance;
            emit BankrollSwept(_player, _amount);
        }

        managersProfit -= int(_amount);
        profitOf[msg.sender] -= int(_amount);

        // transfer ERC20 from the vault to the winner
        ERC20.transfer(_player, _amount);

        emit Debit(msg.sender, _player, _amount);
    }

    function credit(uint256 _amount) external {
        if (!managers[msg.sender]) revert FORBIDDEN();

        managersProfit += int(_amount);
        profitOf[msg.sender] += int(_amount);

        // transfer ERC20 from the manager to the vault
        ERC20.transferFrom(msg.sender, address(this), _amount);

        emit Credit(msg.sender, _amount);
    }

    function claimProfit() external {
        if (!managers[msg.sender]) revert FORBIDDEN();

        // substract the bankroll lpFee and leave it in the this contract
        int256 _profit = profitOf[msg.sender];

        // check if there is profit to claim
        if (_profit < 1) revert NO_PROFIT();

        uint256 _lpsProfit = (uint(_profit) * lpFee) / DENOMINATOR;

        lpsProfit += int(_lpsProfit);
        managersProfit -= _profit;
        _profit -= int(_lpsProfit);

        profitOf[msg.sender] = 0;

        // transfer ERC20 from the vault to the manager
        ERC20.transfer(msg.sender, uint256(_profit));

        emit ProfitClaimed(msg.sender, uint256(_profit));
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

    function setFee(uint16 _lpFee) external {
        if (msg.sender != admin) revert FORBIDDEN();
        lpFee = _lpFee;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function liquidity() public view returns (uint256 _balance) {
        uint256 _reservedProfit = managersProfit > 0 ? uint(managersProfit) : 0;
        _balance = ERC20.balanceOf(address(this)) - _reservedProfit;
    }

    // function expectedLiquidityProfit() public view returns (int256 _balance) {
    //     _balance =
    //         int(lpsProfit) +
    //         (managersProfit * int16(lpFee)) /
    //         int(DENOMINATOR);
    // }

    //TODO: rename getInvestment
    function getInvestorValue(
        address _investor
    ) external view returns (int256 _amount) {
        int256 _deposited = int(depositOf[_investor]);
        int256 _profit = getInvestorProfit(_investor);
        _amount = _deposited + _profit;
    }

    function getInvestorProfit(
        address _investor
    ) public view returns (int256 _profit) {
        _profit =
            ((int(liquidity()) * int(sharesOf[_investor])) / int(totalSupply)) -
            int(depositOf[_investor]);
    }

    // function getExpectedInvestorProfit(
    //     address _investor
    // ) public view returns (int256 _profit) {
    //     _profit = ((expectedLiquidityProfit() * int(sharesOf[_investor])) /
    //         int(totalSupply));
    // }

    function getInvestorStake(
        address _investor
    ) external view returns (uint256 _stake) {
        uint256 _shares = sharesOf[_investor];
        _stake = _shares == 0 ? 0 : (_shares * DENOMINATOR) / totalSupply;
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

    function _withdraw(uint256 _shares, address _sender) internal {
        // uint256 liq = uint(expectedLiquidityProfit()) + totalDeposit;

        // Calculate the amount of ERC20 worth of shares
        uint256 amount = (_shares * liquidity()) / totalSupply;

        // uint256 investorProfit = amount - depositOf[_sender];

        // Remove only profit
        //if (investorProfit > 0) lpsProfit -= investorProfit;

        // Burn the shares from the caller
        _burn(msg.sender, _shares);

        // Transfer ERC20 to the caller
        ERC20.transfer(msg.sender, amount);

        emit FundsWithdrawn(msg.sender, amount);
    }
}
