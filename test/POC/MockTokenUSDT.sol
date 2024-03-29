// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* Openzeppelin Contract */

contract MockTokenUSDT {
    constructor(string memory _name, string memory _symbol) {}
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
        /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */

    function approve(address _spender, uint _value) public  {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
    }

        function mint(address _user, uint256 _quantity) external {
        balances[_user] += _quantity;
    }

        function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint _value) public {
        uint256 _allowance = allowed[_from][msg.sender];

        if (_allowance < type(uint256).max) {
            allowed[_from][msg.sender] = _allowance - _value;
        }
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
    }
}
