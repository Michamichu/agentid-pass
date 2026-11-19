// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Minimal interface of the official Binance Agent ID contract
/// (SPACE ID Agent ID, ERC-721, non-transferable). Only balanceOf is needed:
/// a return value > 0 means the address holds an Agent ID.
interface IAgentID {
    function balanceOf(address account) external view returns (uint256);
}

/// @title AgentID Pass
/// @notice Free commemorative NFT for Binance Agent ID holders.
/// @dev Built for the Binance Wallet Agent ID Hackathon (submission period
/// 18 Nov – 9 Dec 2026). Agent ID is used for ACCESS CONTROL: only an
/// address that holds an Agent ID (balanceOf > 0 on the official contract)
/// can mint, exactly once, for free. Each mint is therefore a genuine
/// on-chain interaction by an Agent ID address.
///
/// Safety rules respected (per the hackathon announcement):
/// - No QR-code / pairing-code login anywhere; this contract never handles
///   wallet sessions.
/// - No bypassed confirmations: mint() is a plain user-signed transaction.
/// - No unauthorized transfers: the contract never moves user assets; it only
///   mints a new token to the caller.
/// - Open-source: source is verified on BscScan at deploy time.
/// - No promised returns: the pass is a free commemorative badge, no yield,
///   no income, no financial promise of any kind.
///
/// Admin powers are deliberately minimal: the owner can only open/close
/// minting. No fees, no royalties, no pausing of transfers, no metadata
/// changes after deploy, no upgradeability, no proxy.
contract AgentIDPass is ERC721, Ownable {
    using Strings for uint256;

    /// @notice Minting is currently closed.
    error MintClosed();
    /// @notice Caller does not hold a Binance Agent ID.
    error NotAgentIDHolder();
    /// @notice Caller already minted their one pass.
    error AlreadyMinted();
    /// @notice Max supply reached.
    error MaxSupplyReached();

    /// @notice Official Binance Agent ID contract on BNB Chain.
    IAgentID public immutable agentId;
    /// @notice Hard cap on total passes. Production value: 10,000.
    uint256 public immutable maxSupply;
    /// @notice Number of passes minted so far; also the next token id.
    uint256 public totalMinted;
    /// @notice Whether minting is currently open (owner-controlled).
    bool public mintOpen;
    /// @notice Tracks which wallets already claimed their one pass.
    mapping(address => bool) public hasMinted;

    event MintingOpened();
    event MintingClosed();
    event PassMinted(address indexed minter, uint256 indexed tokenId);

    /// @param agentId_ Address of the official Agent ID contract.
    /// @param maxSupply_ Hard cap (10,000 for the production deployment).
    /// @param owner_ Address that may open/close minting.
    constructo(address agentId_, uint256 maxSupply_, address owner_)   
        ERC721("AgentID Pass", "AIDP")
                Ownable(owner_)
    {
        agentId = IAgentID(agentId_);
        maxSupply = maxSupply_;
    }

    /// @notice Open or close minting. Only the owner.
    function setMintOpen(bool open_) external onlyOwner {
        mintOpen = open_;
        if (open_) {
            emit MintingOpened();
        } else {
            emit MintingClosed();
        }
    }

    /// @notice Mint one free pass. Caller must hold an Agent ID and must not
    /// have minted before. Free: no value accepted (non-payable).
    function mint() external {
        if (!mintOpen) revert MintClosed();
        if (agentId.balanceOf(msg.sender) < 1) revert NotAgentIDHolder();
        if (hasMinted[msg.sender]) revert AlreadyMinted();
        if (totalMinted >= maxSupply) revert MaxSupplyReached();

        hasMinted[msg.sender] = true;
        uint256 tokenId = ++totalMinted;
        emit PassMinted(msg.sender, tokenId);
        _safeMint(msg.sender, tokenId);
    }

    /// @notice Fully on-chain metadata: base64 JSON with an embedded
    /// base64 SVG badge. No external URLs anywhere.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory svg = _svg(tokenId);
        string memory json = string.concat(
            '{"name":"AgentID Pass #',
            tokenId.toString(),
            '","description":"Commemorative pass for Binance Agent ID holders. Free mint, one per Agent ID holder. Built for the Binance Wallet Agent ID Hackathon.","image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '","attributes":[{"trait_type":"Type","value":"Agent ID Holder Pass"}]}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    /// @notice Dark badge SVG showing the token id and "AGENT ID HOLDER".
    function _svg(uint256 tokenId) internal pure returns (string memory) {
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">',
            '<rect width="512" height="512" fill="#0b0b12"/>',
            '<rect x="24" y="24" width="464" height="464" rx="24" fill="none" stroke="#f0b90b" stroke-width="4"/>',
            '<text x="256" y="150" font-family="sans-serif" font-size="44" font-weight="bold" fill="#f0b90b" text-anchor="middle">AGENTID PASS</text>',
            '<text x="256" y="250" font-family="sans-serif" font-size="72" font-weight="bold" fill="#ffffff" text-anchor="middle">#',
            tokenId.toString(),
            '</text>',
            '<text x="256" y="330" font-family="sans-serif" font-size="28" fill="#ffffff" text-anchor="middle">AGENT ID HOLDER</text>',
            '<text x="256" y="380" font-family="sans-serif" font-size="20" fill="#8a8a9a" text-anchor="middle">BNB CHAIN</text>',
            '</svg>'
        );
    }
}
