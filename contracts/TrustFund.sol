// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TrustFund {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastWithdrawalTime;
    address public owner;
    uint256 public minTimeBetweenWithdrawals = 30 minutes;
    uint256 public maxWithdrawalAmount = 1 ether;

    // Events
    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);

    // Modifier to only allow specific addresses to execute certain functions
    modifier onlyAuthorized() {
        require(msg.sender == owner || msg.sender == 0x3cC92b7496571fC479EB4714784a6839CD3e57f2, "Unauthorized");
        _;
    }

    // Modifier to enforce minimum time between withdrawals
    modifier timeBetweenWithdrawals() {
        require(block.timestamp - lastWithdrawalTime[msg.sender] >= minTimeBetweenWithdrawals, "Too soon for another withdrawal");
        _;
    }

    // Constructor to set the contract owner
    constructor() {
        owner = msg.sender;
    }

    // Fallback function to receive Ether
    receive() external payable {
        deposit();
    }

    // Function to deposit Ether to the contract
    function deposit() internal {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // Function to allow owner to change the minimum time between withdrawals
    function setMinTimeBetweenWithdrawals(uint256 _time) external onlyAuthorized {
        minTimeBetweenWithdrawals = _time;
    }

    // Function to allow owner to change the maximum withdrawal amount
    function setMaxWithdrawalAmount(uint256 _amount) external onlyAuthorized {
        maxWithdrawalAmount = _amount;
    }

    // Function to withdraw Ether from the contract
    function withdraw(uint256 _amount) external onlyAuthorized timeBetweenWithdrawals {
        uint256 amount = _amount * 1000000000000000000;
        require(amount <= maxWithdrawalAmount, "Amount exceeds maximum withdrawal limit");
        require(amount <= balances[msg.sender], "Insufficient balance");


        balances[msg.sender] -= amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;

        // Interactions
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    // Function to allow owner to withdraw any remaining balance
    function withdrawRemainingBalance() external onlyAuthorized {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        // Effects
        balances[msg.sender] = 0;

        // Interactions
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    // Function to allow owner to transfer ownership
    function transferOwnership(address _newOwner) external onlyAuthorized {
        owner = _newOwner;
    }
}
