# Arbitrum Stylus Examples

Two smart contracts written in Rust, compiled to WASM, deployed on Arbitrum Sepolia via [Stylus](https://docs.arbitrum.io/stylus/gentle-introduction).

Stylus lets you write smart contracts in Rust (or C/C++), compile them to WASM, and run them on Arbitrum alongside normal Solidity/EVM contracts. It's cheaper for compute-heavy stuff because WASM execution costs less gas than the EVM for the same work (usually).

These two examples show what writing Solidity-equivalent contracts in Rust with the Stylus SDK looks like. They're not production contracts, just learning material.

## What each example teaches

| | [Escrow](escrow/) | [Ballot](ballot/) |
|---|---|---|
| **Core idea** | Hold funds until both parties agree | Commit-reveal voting for two candidates |
| **Storage** | `StorageAddress`, `StorageU256`, `StorageBool` | `StorageMap`, `StorageFixedBytes`, phase as `StorageU256` |
| **Patterns** | Calling external contracts (ERC-20) via `sol_interface!` | Hashing with `keccak`, phase-based state machine |
| **Flow** | deposit -> ship -> receive | register -> commit -> reveal -> tally |

Both projects include a Solidity version of the same contract in `src/solidity/` so you can compare side-by-side.

## Prerequisites

You can deploy these locally using nitro-devnode, [follow the guide here](https://docs.arbitrum.io/stylus/quickstart#setting-up-your-development-environment)

For demo purposes, I found it more interesting to deploy on Arbitrum Sepolia so we can actually see the transactions on the Arbiscan explorer (yey).

In any case you need these:

- **Rust** - handled by the `rust-toolchain.toml` at the repo root (1.88, wasm32 target). Just have [rustup](https://rustup.rs/) installed and it'll pick up the right toolchain automatically.
- **cargo-stylus** - `cargo install --force cargo-stylus`
- **Foundry** - `forge` and `cast`. Install from [getfoundry.sh](https://book.getfoundry.sh/).
- **Funded Arbitrum Sepolia accounts** - escrow needs 2 (buyer + seller), ballot needs 6 (admin + 5 voters). All need sETH. You can use my very own pet project [A Better Faucet](https://abetterfaucet.xyz) or any other faucet (but please use mine 🙏)

## Quick start

```bash
cp .env.example .env.escrow   # fill BUYER_PK and SELLER_PK
cp .env.example .env.ballot   # fill ADMIN_PK and VOTER1_PK through VOTER5_PK

# Escrow
make -C escrow setup           # deploy mock USDC, mint tokens, write .config
make -C escrow demo            # deploy escrow, run deposit -> ship -> receive

# Ballot
make -C ballot setup           # deploy ballot, register 5 voters, advance to commit phase
make -C ballot demo            # run full commit -> reveal -> tally
```

Each step prints Arbiscan links so you can verify transactions on-chain.
