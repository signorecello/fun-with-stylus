#![cfg_attr(not(any(test, feature = "export-abi")), no_main)]
extern crate alloc;

use stylus_sdk::prelude::*;
use stylus_sdk::storage::{StorageAddress, StorageBool, StorageFixedBytes, StorageMap, StorageU256};
use stylus_sdk::alloy_primitives::{Address, FixedBytes, U256};

// what is keccak? that's SHA3 and the standard hash function for Ethereum
// but again it's an type you import from stylus_sdk
use stylus_sdk::crypto::keccak;

#[storage]
#[entrypoint]
pub struct Ballot {
    admin: StorageAddress,
    registered: StorageMap<Address, StorageBool>,
    commits: StorageMap<Address, StorageFixedBytes<32>>, // keccak returns 32 bytes so we're using the equivalent of Solidity's bytes32
    revealed: StorageMap<Address, StorageBool>,
    votes_a: StorageU256,
    votes_b: StorageU256,
    phase: StorageU256,
}

#[public]
impl Ballot {
    // admin registers a voter (phase 0 only).
    pub fn register(&mut self, voter: Address) {
        let vm = self.vm().clone();
        let caller = vm.msg_sender();
        let admin = self.admin.get();

        // First call sets the admin
        if admin == Address::ZERO {
            self.admin.set(caller);
        } else {
            // in Solidity you'd use modifiers, like "onlyAdmin" that run before the function
            // here we just check manually
            assert_eq!(caller, admin, "only admin");
        }

        assert_eq!(self.phase.get(), U256::ZERO, "not setup phase");
        self.registered.setter(voter).set(true);
    }

    // admin advances the phase: 0->1->2->3.
    pub fn advance_phase(&mut self) {
        let vm = self.vm().clone();
        assert_eq!(vm.msg_sender(), self.admin.get(), "only admin");

        let current = self.phase.get();
        assert!(current < U256::from(3), "already done");
        self.phase.set(current + U256::from(1));
    }

    // voter submits a commit hash (phase 1 only).
    // hash should be keccak256(abi.encode(vote, salt)) computed off-chain, see the demo.sh for examples
    pub fn commit(&mut self, hash: FixedBytes<32>) {
        let vm = self.vm().clone();
        let caller = vm.msg_sender();

        assert_eq!(self.phase.get(), U256::from(1), "not commit phase");
        assert!(self.registered.get(caller), "not registered");
        assert_eq!(
            self.commits.get(caller),
            FixedBytes::<32>::ZERO,
            "already committed"
        );

        self.commits.setter(caller).set(hash);
    }

    // voter reveals their vote and salt (phase 2 only).
    // vote=0 for candidate A, vote=1 for candidate B.
    pub fn reveal(&mut self, vote: U256, salt: FixedBytes<32>) {
        let vm = self.vm().clone();
        let caller = vm.msg_sender();

        assert_eq!(self.phase.get(), U256::from(2), "not reveal phase");
        assert!(self.registered.get(caller), "not registered");
        assert!(!self.revealed.get(caller), "already revealed");

        // Reconstruct abi.encode(vote, salt): two 32-byte words concatenated
        let mut preimage = [0u8; 64];
        preimage[..32].copy_from_slice(&vote.to_be_bytes::<32>());
        preimage[32..].copy_from_slice(salt.as_slice());

        let expected: FixedBytes<32> = keccak(preimage).into();
        let committed = self.commits.get(caller);
        assert_eq!(expected, committed, "hash mismatch");

        self.revealed.setter(caller).set(true);

        if vote == U256::ZERO {
            self.votes_a.set(self.votes_a.get() + U256::from(1));
        } else {
            self.votes_b.set(self.votes_b.get() + U256::from(1));
        }
    }

    // returns the current phase (0=setup, 1=commit, 2=reveal, 3=done).
    pub fn get_phase(&self) -> U256 {
        self.phase.get()
    }

    // returns (votes_a, votes_b).
    pub fn get_votes(&self) -> (U256, U256) {
        (self.votes_a.get(), self.votes_b.get())
    }
}
