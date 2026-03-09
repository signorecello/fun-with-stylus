-include ../.env.ballot
-include .config

RPC      ?= https://arbitrum-sepolia-rpc.publicnode.com
ARBISCAN := https://sepolia.arbiscan.io

export ADMIN_PK VOTER1_PK VOTER2_PK VOTER3_PK VOTER4_PK VOTER5_PK RPC ARBISCAN
export BALLOT_ADDR ADMIN_ADDR

.PHONY: check setup demo

check:
	cargo stylus check -e $(RPC)

setup:
	@test -n "$(ADMIN_PK)"  || { echo "error: ADMIN_PK not set (add it to .env.ballot)";  exit 1; }
	@test -n "$(VOTER1_PK)" || { echo "error: VOTER1_PK not set (add it to .env.ballot)"; exit 1; }
	@test -n "$(VOTER2_PK)" || { echo "error: VOTER2_PK not set (add it to .env.ballot)"; exit 1; }
	@test -n "$(VOTER3_PK)" || { echo "error: VOTER3_PK not set (add it to .env.ballot)"; exit 1; }
	@test -n "$(VOTER4_PK)" || { echo "error: VOTER4_PK not set (add it to .env.ballot)"; exit 1; }
	@test -n "$(VOTER5_PK)" || { echo "error: VOTER5_PK not set (add it to .env.ballot)"; exit 1; }
	@bash scripts/setup.sh

demo:
	@test -n "$(ADMIN_PK)"    || { echo "error: ADMIN_PK not set (add it to .env.ballot)";       exit 1; }
	@test -n "$(VOTER1_PK)"   || { echo "error: VOTER1_PK not set (add it to .env.ballot)";      exit 1; }
	@test -n "$(BALLOT_ADDR)" || { echo "error: BALLOT_ADDR not set — run 'make setup' first"; exit 1; }
	@bash scripts/demo.sh
