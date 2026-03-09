# Escrow on Arbitrum Stylus

A minimal escrow smart contract written in Rust, compiled to WASM, and deployed to Arbitrum Sepolia via [Stylus](https://docs.arbitrum.io/stylus/gentle-introduction).

Demonstrates the full escrow flow: deposit, confirm shipment, confirm receipt. 

There's a setup phase that deploys a mock ERC-20 (USDC) token on a arbitrum sepolia testnet. Once you run the `make setup` step, that will show in a `.config` file along with addresses and other stuff.

## Prerequisites

- [Rust](https://rustup.rs/), set toolchain to `1.81` (`rustup default 1.81`)
- `wasm32-unknown-unknown` target installed (`rustup target add wasm32-unknown-unknown --toolchain 1.81`)
- `cargo-stylus` (install with `cargo install --force cargo-stylus`)
- [Foundry](https://book.getfoundry.sh/) (`forge`, `cast`)
- Two Arbitrum Sepolia accounts funded with sETH. Shamelessly promoting my toy faucet project [A Better Faucet](https://abetterfaucet.xyz) but you can use others.

## Quick start

`cp .env.example .env` and then fill the BUYER_PK and SELLER_PK, they both should have some sETH. Add a custom RPC if you're being rate limited or something.

```bash
make setup             # deploy mock USDC, mint tokens, write .config
make demo              # deploy escrow, run the full flow
```

Each transaction prints an Arbiscan link. I had some fun verifying the escrow contract on Arbiscan using [these instructions](https://docs.arbitrum.io/stylus/how-tos/verifying-contracts-arbiscan), but AFAIK you can't do it with forge and it doesn't seem to support contracts written with Stylus version >0.6.1 yet