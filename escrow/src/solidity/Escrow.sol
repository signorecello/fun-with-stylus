// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ERC20 is a type of contract that holds digital, fungible assets
// USDc is an example of an ERC20 token which is pegged to the US dollar
// They all share the same interface. For now we only care about these two functions:
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Escrow {
    address public buyer;
    address public seller;
    address public usdc;
    uint256 public amount;
    bool public shipped;
    bool public received;

    function deposit(address _seller, address _usdc, uint256 _amount) external {
        // msg.sender and address(this) are globally available in Solidity
        // in Stylus you get them from self.vm()
        IERC20(_usdc).transferFrom(msg.sender, address(this), _amount);

        buyer = msg.sender;
        seller = _seller;
        usdc = _usdc;
        amount = _amount;
    }

    function confirmShipped() external {
        // we can check who called this function through msg.sender
        require(msg.sender == seller, "only seller");

        shipped = true;
    }

    function confirmReceived() external {
        require(msg.sender == buyer, "only buyer");

        // if the item was shipped, then we can confirm receipt
        require(shipped, "not shipped yet");
        received = true;

        // and we transfer the USDC to the seller
        IERC20(usdc).transfer(seller, amount);
    }
}
