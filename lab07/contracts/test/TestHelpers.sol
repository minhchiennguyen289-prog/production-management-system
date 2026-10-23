// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {ClassToken} from "../ClassToken.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// TEST ONLY: exposes mint to verify the inherited cap; never used in deploy scripts.
contract ClassTokenHarness is ClassToken {
    constructor(address holder) ClassToken(holder) {}
    function mintForTest(address to, uint256 amount) external { _mint(to, amount); }
}
contract AcceptingReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external pure returns (bytes4)
    { return IERC721Receiver.onERC721Received.selector; }
}
contract NonReceiver {}
contract WrongReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external pure returns (bytes4)
    { return bytes4(0); }
}
