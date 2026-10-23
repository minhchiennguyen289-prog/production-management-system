// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @notice Fixed supply of one million CTK, with capped supply and EIP-2612 permit.
contract ClassToken is ERC20, ERC20Capped, ERC20Permit {
    constructor(address initialHolder)
        ERC20("ClassToken", "CTK")
        ERC20Capped(1_000_000 * 10 ** 18)
        ERC20Permit("ClassToken")
    {
        _mint(initialHolder, cap());
    }

    // super preserves ERC20Capped's cap check in the inheritance chain.
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Capped)
    {
        super._update(from, to, value);
    }
}
