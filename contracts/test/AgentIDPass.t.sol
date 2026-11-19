// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {AgentIDPass} from "../src/AgentIDPass.sol";
import {MockAgentID} from "./mocks/MockAgentID.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Local fork-free tests for AgentIDPass.
/// The Agent ID gate is tested against MockAgentID, which reproduces the
/// real contract's only behaviour this project relies on: balanceOf > 0
/// iff the address holds an Agent ID.
contract AgentIDPassTest is Test {
    AgentIDPass public pass;
    MockAgentID public agentId;

    address public owner = address(0xA11CE);
    address public holder = address(0x1001);
    address public holder2 = address(0x1002);
    address public holder3 = address(0x1003);
    address public stranger = address(0x5007);

    uint256 constant PROD_MAX_SUPPLY = 10_000;

    function setUp() public {
        agentId = new MockAgentID();
        pass = new AgentIDPass(address(agentId), PROD_MAX_SUPPLY, owner);
        agentId.mintTo(holder);
        agentId.mintTo(holder2);
        agentId.mintTo(holder3);
    }

    /// @notice Non-Agent-ID-holder reverts with NotAgentIDHolder.
    function test_RevertWhen_NotAgentIDHolder() public {
        vm.prank(owner);
        pass.setMintOpen(true);
        vm.prank(stranger);
        vm.expectRevert(AgentIDPass.NotAgentIDHolder.selector);
        pass.mint();
    }

    /// @notice An Agent ID holder can mint exactly once, for free.
    function test_HolderCanMintOnce() public {
        vm.prank(owner);
        pass.setMintOpen(true);
        vm.prank(holder);
        pass.mint();
        assertEq(pass.ownerOf(1), holder);
        assertEq(pass.balanceOf(holder), 1);
        assertEq(pass.totalMinted(), 1);
        assertTrue(pass.hasMinted(holder));
    }

    /// @notice A second mint by the same wallet reverts with AlreadyMinted.
    function test_RevertWhen_SecondMintBySameWallet() public {
        vm.prank(owner);
        pass.setMintOpen(true);
        vm.prank(holder);
        pass.mint();
        vm.prank(holder);
        vm.expectRevert(AgentIDPass.AlreadyMinted.selector);
        pass.mint();
    }

    /// @notice Minting while closed reverts with MintClosed (even for holders).
    function test_RevertWhen_MintClosed() public {
        // mintOpen defaults to false
        assertFalse(pass.mintOpen());
        vm.prank(holder);
        vm.expectRevert(AgentIDPass.MintClosed.selector);
        pass.mint();

        // Owner opens, then closes again: still closed.
        vm.prank(owner);
        pass.setMintOpen(true);
        vm.prank(owner);
        pass.setMintOpen(false);
        vm.prank(holder);
        vm.expectRevert(AgentIDPass.MintClosed.selector);
        pass.mint();
    }

    /// @notice Max supply is enforced. Uses a test-only deployment with a
    /// small cap (3) so the cap logic is exercised; the production
    /// deployment uses 10,000 and this test never changes that.
    function test_MaxSupplyEnforced() public {
        AgentIDPass small = new AgentIDPass(address(agentId), 3, owner);
        vm.prank(owner);
        small.setMintOpen(true);

        vm.prank(holder);
        small.mint();
        vm.prank(holder2);
        small.mint();
        vm.prank(holder3);
        small.mint();
        assertEq(small.totalMinted(), 3);

        // A fourth, fresh Agent ID holder must hit the cap.
        address holder4 = address(0x1004);
        agentId.mintTo(holder4);
        vm.prank(holder4);
        vm.expectRevert(AgentIDPass.MaxSupplyReached.selector);
        small.mint();
    }

    /// @notice tokenURI returns a data:application/json;base64 URI.
    /// The full decoded payload is verified off-chain from the logged
    /// output (see test_LogTokenURI).
    function test_TokenURIHasBase64JsonPrefix() public {
        vm.prank(owner);
        pass.setMintOpen(true);
        vm.prank(holder);
        pass.mint();
        string memory uri = pass.tokenURI(1);
        bytes memory prefix = bytes("data:application/json;base64,");
        for (uint256 i = 0; i < prefix.length; i++) {
            assertEq(bytes(uri)[i], prefix[i]);
        }
        assertGt(bytes(uri).length, prefix.length + 100);
    }

    /// @notice Logs the full tokenURI so its decoded JSON + SVG can be
    /// verified off-chain (forge test -vvv, then base64-decode).
    function test_LogTokenURI() public {
        vm.prank(owner);
        pass.setMintOpen(true);
        vm.prank(holder);
        pass.mint();
        console.log(pass.tokenURI(1));
    }

    /// @notice tokenURI for a nonexistent token reverts.
    function test_RevertWhen_TokenURINonexistent() public {
        vm.expectRevert();
        pass.tokenURI(999);
    }

    /// @notice Owner can toggle minting open/closed.
    function test_OwnerCanToggleMinting() public {
        assertFalse(pass.mintOpen());
        vm.prank(owner);
        pass.setMintOpen(true);
        assertTrue(pass.mintOpen());
        vm.prank(owner);
        pass.setMintOpen(false);
        assertFalse(pass.mintOpen());
    }

    /// @notice Non-owner cannot toggle minting.
    function test_RevertWhen_NonOwnerToggles() public {
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, stranger));
        pass.setMintOpen(true);
    }

    /// @notice mint() is non-payable: sending value reverts.
    function test_RevertWhen_SendValue() public {
        vm.prank(owner);
        pass.setMintOpen(true);
        vm.deal(holder, 1 ether);
        vm.prank(holder);
        // Raw call: the compiler forbids {value:} on a non-payable
        // function at compile time, so exercise it via a low-level call.
        (bool ok,) = address(pass).call{value: 0.01 ether}(
            abi.encodeWithSelector(AgentIDPass.mint.selector)
        );
        assertFalse(ok);
    }

    /// @notice Name, symbol and production cap are exactly as specified.
    function test_Metadata() public view {
        assertEq(pass.name(), "AgentID Pass");
        assertEq(pass.symbol(), "AIDP");
        assertEq(pass.maxSupply(), PROD_MAX_SUPPLY);
        assertEq(address(pass.agentId()), address(agentId));
        assertEq(pass.owner(), owner);
    }
}
