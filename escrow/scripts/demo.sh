#!/usr/bin/env bash
# E2E demo: full escrow flow on Arbitrum Sepolia
set -euo pipefail

: "${RPC:?RPC must be set}"
: "${BUYER_PK:?BUYER_PK must be set}"
: "${SELLER_PK:?SELLER_PK must be set}"
: "${BUYER_ADDR:?BUYER_ADDR must be set}"
: "${SELLER_ADDR:?SELLER_ADDR must be set}"
: "${USDC_ADDR:?USDC_ADDR must be set}"
: "${ESCROW_ADDR:?ESCROW_ADDR must be set}"
: "${ARBISCAN:?ARBISCAN must be set}"

AMOUNT="100000000" # 100 USDC (6 decimals), should be enough for a beer in Lisbon these days

# Helper to send a transaction and print explorer link
send_tx() {
  local tx_hash
  tx_hash=$(cast send --rpc-url "$RPC" "$@" --json | jq -r '.transactionHash')
  echo "  $ARBISCAN/tx/$tx_hash"
}

balance() {
  cast call --rpc-url "$RPC" "$USDC_ADDR" "balanceOf(address)(uint256)" "$1"
}

echo "Buyer balance:  $(balance "$BUYER_ADDR")"
echo "Seller balance: $(balance "$SELLER_ADDR")"

# Step 1: Buyer deposits into escrow
echo ""
echo "Buyer deposits $AMOUNT into escrow..."
send_tx --private-key "$BUYER_PK" \
  "$ESCROW_ADDR" "deposit(address,address,uint256)" "$SELLER_ADDR" "$USDC_ADDR" "$AMOUNT"

echo "Buyer balance:  $(balance "$BUYER_ADDR")"
echo "Escrow balance: $(balance "$ESCROW_ADDR")"

# Step 2: Seller confirms shipment
echo ""
echo "Seller confirms shipment..."
send_tx --private-key "$SELLER_PK" \
  "$ESCROW_ADDR" "confirmShipped()"

# Step 3: Buyer confirms receipt. Seller gets paid
echo "Buyer confirms receipt..."
send_tx --private-key "$BUYER_PK" \
  "$ESCROW_ADDR" "confirmReceived()"

echo ""
echo "Buyer balance:  $(balance "$BUYER_ADDR")"
echo "Seller balance: $(balance "$SELLER_ADDR")"
echo "Escrow balance: $(balance "$ESCROW_ADDR")"
