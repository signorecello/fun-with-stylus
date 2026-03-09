-include ../.env.escrow
-include .config

RPC      ?= https://arbitrum-sepolia-rpc.publicnode.com
ARBISCAN := https://sepolia.arbiscan.io

export BUYER_PK SELLER_PK BUYER_ADDR SELLER_ADDR USDC_ADDR RPC ARBISCAN

.PHONY: check setup demo

check:
	cargo stylus check -e $(RPC)

setup:
	@test -n "$(BUYER_PK)"  || { echo "error: BUYER_PK not set (add it to .env)";  exit 1; }
	@test -n "$(SELLER_PK)" || { echo "error: SELLER_PK not set (add it to .env)"; exit 1; }
	@bash scripts/setup.sh

demo:
	@test -n "$(BUYER_PK)"  || { echo "error: BUYER_PK not set (add it to .env)";  exit 1; }
	@test -n "$(SELLER_PK)" || { echo "error: SELLER_PK not set (add it to .env)"; exit 1; }
	@test -n "$(USDC_ADDR)" || { echo "error: USDC_ADDR not set — run 'make setup' first"; exit 1; }
	@NONCE=$$(cast nonce --rpc-url '$(RPC)' '$(BUYER_ADDR)') && \
	ESCROW_ADDR=$$(cast compute-address '$(BUYER_ADDR)' --nonce "$$NONCE" | grep -ioE '0x[0-9a-fA-F]{40}') && \
	echo "==> Deploying escrow to Arbitrum Sepolia..." && \
	cargo stylus deploy --endpoint='$(RPC)' --private-key='$(BUYER_PK)' --max-fee-per-gas-gwei 1 > /dev/null 2>&1 && \
	cast send --rpc-url '$(RPC)' --private-key '$(BUYER_PK)' \
		'$(USDC_ADDR)' "approve(address,uint256)" "$$ESCROW_ADDR" "100000000000" > /dev/null && \
	export ESCROW_ADDR && \
	bash scripts/demo.sh
