// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @notice Deliberately vulnerable lab fixture. Local testing only.
contract EtherBankVulnerable {
    mapping(address => uint256) public balances;
    address public owner;
    constructor() { owner = msg.sender; }
    function deposit() external payable { balances[msg.sender] += msg.value; }
    function withdraw() external {
        uint256 bal = balances[msg.sender];
        require(bal > 0, "no balance");
        (bool ok,) = msg.sender.call{value: bal}(""); // BUG: interaction before effect
        require(ok, "transfer failed");
        balances[msg.sender] = 0;
    }
    function setOwner(address newOwner) external { owner = newOwner; } // BUG: no authorization
}
