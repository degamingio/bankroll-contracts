// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* Openzeppelin Contract */
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MockTokenUSDT is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
        /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint _value) public virtual override returns (bool) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowance(msg.sender, _spender) != 0)));

        _approve(msg.sender, _spender, _value);
    }

        function mint(address _user, uint256 _quantity) external {
        _mint(_user, _quantity);
    }
}
