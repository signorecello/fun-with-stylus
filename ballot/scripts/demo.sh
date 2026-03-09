#!/usr/bin/env bash
# E2E demo: commit-reveal voting on Arbitrum Sepolia
set -euo pipefail

: "${RPC:?RPC must be set}"
: "${BALLOT_ADDR:?BALLOT_ADDR must be set}"
: "${ARBISCAN:?ARBISCAN must be set}"
: "${ADMIN_PK:?ADMIN_PK must be set}"
: "${VOTER1_PK:?VOTER1_PK must be set}"
: "${VOTER2_PK:?VOTER2_PK must be set}"
: "${VOTER3_PK:?VOTER3_PK must be set}"
: "${VOTER4_PK:?VOTER4_PK must be set}"
: "${VOTER5_PK:?VOTER5_PK must be set}"

# same helper to send a tx and print arviscan link
send_tx() {
  local tx_hash
  tx_hash=$(cast send --rpc-url "$RPC" "$@" --json | jq -r '.transactionHash')
  echo "  $ARBISCAN/tx/$tx_hash"
}

# A will win, sorry B
VOTER_PKS=("$VOTER1_PK" "$VOTER2_PK" "$VOTER3_PK" "$VOTER4_PK" "$VOTER5_PK")
VOTES=(0 1 0 1 0)  # 3 for A, 2 for B

echo "==> Phase 1: Commit votes"
echo ""

# each voter is supposed to know their salt (secret)
# commit-reveal assumes a lot of things including that
# failing to reveal isn't a big deal
# IRL it IS a big deal, that's why commit-reveal isn't really useable
SALTS=()

for i in 0 1 2 3 4; do
  PK="${VOTER_PKS[$i]}"
  VOTE="${VOTES[$i]}"
  ADDR=$(cast wallet address "$PK")

  # generate random salt/secret
  SALT="0x$(openssl rand -hex 32)"
  SALTS+=("$SALT")

  # yes I'm lazy and I'm using cast just for a keccak function
  HASH=$(cast keccak "$(cast abi-encode "f(uint256,bytes32)" "$VOTE" "$SALT")")

  CANDIDATE="A"
  if [ "$VOTE" -eq 1 ]; then CANDIDATE="B"; fi

  echo "Voter $((i+1)) ($ADDR) commits vote for candidate $CANDIDATE..."
  send_tx --private-key "$PK" "$BALLOT_ADDR" "commit(bytes32)" "$HASH"
done

# voter1 is also the admin btw
# it advances to the reveal phase
echo ""
echo "==> Admin advances to reveal phase..."
send_tx --private-key "$ADMIN_PK" "$BALLOT_ADDR" "advancePhase()"

PHASE=$(cast call --rpc-url "$RPC" "$BALLOT_ADDR" "getPhase()(uint256)")
echo "  Current phase: $PHASE (2=reveal)"

echo ""
echo "==> Phase 2: Reveal votes"
echo ""

for i in 0 1 2 3 4; do
  PK="${VOTER_PKS[$i]}"
  VOTE="${VOTES[$i]}"
  SALT="${SALTS[$i]}"
  ADDR=$(cast wallet address "$PK")

  CANDIDATE="A"
  if [ "$VOTE" -eq 1 ]; then CANDIDATE="B"; fi

  echo "Voter $((i+1)) ($ADDR) reveals vote for candidate $CANDIDATE..."
  send_tx --private-key "$PK" "$BALLOT_ADDR" "reveal(uint256,bytes32)" "$VOTE" "$SALT"
done

# then advances to the done phase
echo ""
echo "==> Admin advances to done..."
send_tx --private-key "$ADMIN_PK" "$BALLOT_ADDR" "advancePhase()"

# results should be 3 for A, 2 for B
echo ""
echo "==> Final results"
RESULT=$(cast call --rpc-url "$RPC" "$BALLOT_ADDR" "getVotes()(uint256,uint256)")
VOTES_A=$(echo "$RESULT" | sed -n '1p')
VOTES_B=$(echo "$RESULT" | sed -n '2p')

echo "  Candidate A: $VOTES_A votes"
echo "  Candidate B: $VOTES_B votes"
echo ""
echo "  Ballot contract: $ARBISCAN/address/$BALLOT_ADDR"
