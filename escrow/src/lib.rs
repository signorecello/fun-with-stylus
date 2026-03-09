#![cfg_attr(not(any(test, feature = "export-abi")), no_main)]
extern crate alloc;

use stylus_sdk::prelude::*;
use stylus_sdk::storage::{StorageAddress, StorageBool, StorageU256};
use stylus_sdk::alloy_primitives::{Address, U256};

// ERC20 is a type of contract that holds digital, fungible assets
// USDc is an example of an ERC20 token which is pegged to the US dollar
// They all share the same interface. For now we only care about these two functions:
sol_interface! {
    interface IERC20 {
        function transfer(address to, uint256 amount) external returns (bool);
        function transferFrom(address from, address to, uint256 amount) external returns (bool);
    }
}

// When we write a Smart Contract using Solidity, it has types built-in and ready for the Ethereum Virtual Machine
// Stylus compiles to WASM, so we use the types provided by the Stylus SDK
#[storage]
#[entrypoint]
pub struct Escrow {
    buyer: StorageAddress,
    seller: StorageAddress,
    usdc: StorageAddress,
    amount: StorageU256,
    shipped: StorageBool,
    received: StorageBool,
}

#[public]
impl Escrow {
    pub fn deposit(&mut self, seller: Address, usdc: Address, amount: U256) -> Result<(), Vec<u8>> {
        // self.vm() exposes things about the blockchain it's running on
        let vm = self.vm().clone();
        let caller = vm.msg_sender();
        let this = vm.contract_address();

        // we create an instance of the ERC20 token contract at the contract address we're passing to the function
        let token = IERC20::new(usdc);

        // and deposit it to "this": this contract
        token.transfer_from(&vm, Call::new_mutating(self), caller, this, amount)?;

        // and we inform the contract about the new values
        self.buyer.set(caller);
        self.seller.set(seller);
        self.usdc.set(usdc);
        self.amount.set(amount);
        Ok(())
    }

    pub fn confirm_shipped(&mut self) {
        // we can check who called this function through msg_sender(), and check it is indeed the seller
        let vm = self.vm().clone();
        assert_eq!(vm.msg_sender(), self.seller.get());

        self.shipped.set(true);
    }

    pub fn confirm_received(&mut self) -> Result<(), Vec<u8>> {
        let vm = self.vm().clone();
        assert_eq!(vm.msg_sender(), self.buyer.get());

        // if the item was shipped, then we can confirm receipt
        assert!(self.shipped.get());
        self.received.set(true);
        
        // and we transfer the USDC to the seller
        let (seller, amount, usdc) = (self.seller.get(), self.amount.get(), self.usdc.get());
        IERC20::new(usdc).transfer(&vm, Call::new_mutating(self), seller, amount)?;
        Ok(())
    }
}