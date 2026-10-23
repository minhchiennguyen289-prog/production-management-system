// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Student badges with JSON and SVG generated entirely on-chain.
contract ClassBadge is ERC721, Ownable {
    using Strings for uint256;
    error EmptyName();

    uint256 private _nextTokenId;
    mapping(uint256 => string) private _studentNames;

    constructor(address initialOwner)
        ERC721("ClassBadge", "CBADGE")
        Ownable(initialOwner)
    {}

    function mint(address to, string memory studentName)
        external onlyOwner returns (uint256 tokenId)
    {
        if (bytes(studentName).length == 0) revert EmptyName();
        tokenId = _nextTokenId++;
        // Set state before _safeMint calls the recipient's receiver hook.
        _studentNames[tokenId] = studentName;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory id = tokenId.toString();
        // User-controlled names live in the JSON trait. The SVG uses only a numeric ID,
        // so no user-controlled XML or markup is inserted into the image.
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="400" viewBox="0 0 640 400">',
            '<rect width="640" height="400" rx="24" fill="#101c35"/>',
            '<rect x="28" y="28" width="584" height="344" rx="16" fill="none" stroke="#55d9bd" stroke-width="2"/>',
            '<text x="56" y="100" fill="#55d9bd" font-family="sans-serif" font-size="20">BLOCKCHAIN / LAB 07</text>',
            '<text x="56" y="195" fill="white" font-family="sans-serif" font-size="44">ClassBadge #', id, '</text>',
            '<text x="56" y="255" fill="#c6d3e9" font-family="sans-serif" font-size="20">ERC-721 / On-chain metadata</text>',
            '</svg>'
        );
        string memory json = string.concat(
            '{"name":"ClassBadge #', id,
            '","description":"Blockchain Lab 07 student badge with on-chain metadata.",',
            '"attributes":[{"trait_type":"Student","value":"',
            _escapeJSON(_studentNames[tokenId]),
            '"}],"image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)), '"}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    /// @dev Escape quotes, backslashes and control bytes; preserve UTF-8 student names.
    function _escapeJSON(string memory value) private pure returns (string memory) {
        bytes memory input = bytes(value);
        bytes memory output = new bytes(input.length * 6);
        bytes16 hexDigits = "0123456789abcdef";
        uint256 n;
        for (uint256 i; i < input.length; ++i) {
            uint8 c = uint8(input[i]);
            if (c == 34 || c == 92) {
                output[n++] = bytes1(uint8(92));
                output[n++] = input[i];
            } else if (c < 32) {
                output[n++] = bytes1(uint8(92));
                output[n++] = "u";
                output[n++] = "0";
                output[n++] = "0";
                output[n++] = hexDigits[c >> 4];
                output[n++] = hexDigits[c & 15];
            } else {
                output[n++] = input[i];
            }
        }
        // Trim unused buffer bytes; output was allocated with capacity input.length * 6.
        assembly { mstore(output, n) }
        return string(output);
    }
}
