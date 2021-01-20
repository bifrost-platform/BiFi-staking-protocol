// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title BiFi's ERC20 Mockup Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract ERC20 {
    string symbol;
    string name;
    uint8 decimals = 18;
    uint256 totalSupply = 1000 * 1e9 * 1e18; // token amount: 1000 Bilions

    // Owner of this contract
    address public owner;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    event Transfer(address, address, uint256);
    event Approval(address, address, uint256);

    // Constructor
    constructor (string memory _name, string memory _symbol) public {

        owner = msg.sender;

        name = _name;
        symbol = _symbol;
        balances[msg.sender] = totalSupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) public returns (bool success) {

        require(balances[msg.sender] >= _amount, "insuficient sender's balance");
        require(_amount > 0, "requested amount must be positive");
        require(balances[_to] + _amount > balances[_to], "receiver's balance overflows");

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to,uint256 _amount) public returns (bool success) {

        require(balances[_from] >= _amount, "insuficient sender's balance");
        require(allowed[_from][msg.sender] >= _amount, "not allowed transfer");
        require(_amount > 0, "requested amount must be positive");
        require(balances[_to] + _amount > balances[_to], "receiver's balance overflows");

        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);

        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract BFCtoken is ERC20 {
    constructor() public ERC20 ("Bifrost", "BFC") {}
}

contract LPtoken is ERC20 {
    constructor() public ERC20 ("BFC-ETH", "LP") {}
}

contract BiFitoken is ERC20 {
    constructor() public ERC20 ("BiFi", "BiFi") {}
}
