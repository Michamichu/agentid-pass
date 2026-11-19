# AgentID Pass — Binance Wallet Agent ID Hackathon

Free commemorative NFT for Binance Agent ID holders. Built for the
**Binance Wallet Agent ID Hackathon** (submission 18 Nov – 9 Dec 2026,
60,000 USDC total prize pool).

## Setup

```bash
cd contracts
forge install OpenZeppelin/openzeppelin-contracts@v5.4.0 foundry-rs/forge-std@v1 --no-commit
forge test
```

## What it is

- **ERC-721** — name `AgentID Pass`, symbol `AIDP`, max supply **10,000**.
- **Free mint, 1 per wallet, value 0** (mint is non-payable — sending BNB
  reverts).
- **Agent ID gate (the hackathon use case):** only an address that holds a
  Binance Agent ID can mint. The contract checks
  `balanceOf(caller) > 0` on the official Agent ID contract
  `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`
  (SPACE ID Agent ID, ERC-721, non-transferable). This is access control —
  an explicitly valid Agent ID use case in the announcement. Every mint is
  a genuine on-chain interaction by an Agent ID address, which is what the
  Project Awards ranking measures.
- **Fully on-chain metadata:** `tokenURI` returns base64 JSON with an
  embedded base64 SVG badge (dark badge, token id, "AGENT ID HOLDER").
  No external URLs, no IPFS, no server dependency.
- **Minimal admin:** the owner can only open/close minting. No fees, no
  royalties, no pausing transfers, no metadata changes, no proxy, no
  upgradeability.

## Live deployment (BNB Chain mainnet)

- Contract: `0xF1EBBD2f505dc98D1E63e578B8780833f19f1158`
- BscScan: https://bscscan.com/address/0xF1EBBD2f505dc98D1E63e578B8780833f19f1158
- Source verified on BscScan (Sourcify exact match).
- Mint website: https://muse.ai/s/agentid-pass-mint-vv6xshjxhyxbfj/KIt60p9MMo29OHE_Ix_Eo2rNtE4TFU8eoCtM-aVi6Mg

## Hackathon safety rules respected

Per the announcement's red lines:

- **No QR-code / pairing-code login** — the contract never handles wallet
  sessions; minting is a plain user-signed transaction.
- **No bypassed confirmations** — no relayer, no meta-transactions, no
  auto-signing; the user sees and confirms the mint themselves.
- **No unauthorized transfers** — the contract never moves user assets;
  it only mints a new token to the caller.
- **Open-source** — source verified on BscScan at deploy time.
- **No promised returns** — the pass is a free commemorative badge; no
  yield, no income, no financial promise of any kind.
- **No brand impersonation** — the project does not use "Binance"/"BNB"
  in its name, token name, or (future) domain.

## Layout

```text
contracts/                  Foundry project
├── src/AgentIDPass.sol     The contract
├── test/AgentIDPass.t.sol  12 forge tests (all passing, local EVM only)
├── test/mocks/MockAgentID.sol  Test-only Agent ID stand-in
├── script/Deploy.s.sol     Deployment script
├── lib/openzeppelin-contracts  OpenZeppelin v5.4.0
└── foundry.toml
```

## Tests

```bash
cd contracts
forge test
```

12 tests, all passing (local EVM only, no network).
