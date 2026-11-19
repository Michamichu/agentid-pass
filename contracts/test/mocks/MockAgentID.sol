// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice Test-only stand-in for the official Binance Agent ID contract.
/// The real contract (0x60b9262456de011f7d15a54cdd8c48baaa8b022f) is an
/// ERC-721 whose balanceOf returns > 0 iff the address holds an Agent ID.
/// This mock reproduces exactly that behaviour for local fork-free tests:
/// anyone can mint Agent ID tokens to any address.
contract MockAgentID is ERC721 {
    uint256 private _nextId = 1;

    constructor() ERC721("Agent ID", "AI") {}

    /// @notice Mint one mock Agent ID to `to`.
    function mintTo(address to) external returns (uint256 tokenId) {
        tokenId = _nextId++;
        _safeMint(to, tokenId);
    }
}
