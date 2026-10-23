// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract EtherBankSecure {
    mapping(address => uint256) public balances;
    address public owner;
    uint256 private status = 1;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    constructor() { owner = msg.sender; }
    modifier nonReentrant() {
        require(status == 1, "ReentrancyGuard: reentrant call");
        status = 2;
        _;
        status = 1;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    function deposit() external payable nonReentrant { balances[msg.sender] += msg.value; }
    function withdraw() external nonReentrant {
        uint256 bal = balances[msg.sender]; // Checks
        require(bal > 0, "no balance");
        balances[msg.sender] = 0; // Effects: invalidate credit BEFORE callback
        (bool ok,) = msg.sender.call{value: bal}(""); // Interactions
        require(ok, "transfer failed");
    }
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero owner");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnerChanged(previousOwner, newOwner);
    }
}

// Worksheet-compatible deployment name; the default bank is patched.
contract EtherBank is EtherBankSecure {}
