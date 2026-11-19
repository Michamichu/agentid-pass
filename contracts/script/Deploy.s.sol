// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AgentIDPass} from "../src/AgentIDPass.sol";

/// @notice Deployment script for AgentIDPass on BNB Chain (chain id 56).
/// @dev RUN ONLY WITH THE USER'S EXPLICIT APPROVAL. This script was NOT
/// executed during development — deployment is a separate, user-approved step.
///
/// Production parameters (hard-coded, do not change without approval):
/// - Agent ID contract: 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F (official,
///   from the Binance announcement)
/// - Max supply: 10,000
/// - Owner: the deployer (set via OWNER env var, defaults to msg.sender)
/// Minting starts CLOSED; the owner opens it with setMintOpen(true) after
/// the project submission form is filled in.
contract Deploy is Script {
    address public constant AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    uint256 public constant MAX_SUPPLY = 10_000;

    function run() external {
        // Safety: refuse to deploy unless the Agent ID contract exists.
        require(AGENT_ID.code.length > 0, "Agent ID contract not found on this chain");
        address owner = vm.envOr("OWNER", msg.sender);

        vm.startBroadcast();
        AgentIDPass pass = new AgentIDPass(AGENT_ID, MAX_SUPPLY, owner);
        vm.stopBroadcast();

        console.log("AgentIDPass deployed at:", address(pass));
        console.log("Owner:", owner);
        console.log("Max supply:", MAX_SUPPLY);
        console.log("Mint open:", pass.mintOpen());
    }
}
