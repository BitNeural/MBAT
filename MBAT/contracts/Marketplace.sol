// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MBATToken.sol";

contract Marketplace {
    MBATToken private token;

    struct Item {
        address seller;
        uint256 price;
        bool isAvailable;
    }

    Item[] public items;

    event ItemListed(uint256 indexed itemId, address indexed seller, uint256 price);
    event ItemSold(uint256 indexed itemId, address indexed buyer, address indexed seller, uint256 price);

    constructor(address tokenAddress) {
        token = MBATToken(tokenAddress);
    }

    modifier onlyItemSeller(uint256 itemId) {
        require(items[itemId].seller == msg.sender, "Not the item seller");
        _;
    }

    modifier itemExists(uint256 itemId) {
        require(itemId < items.length, "Item does not exist");
        _;
    }

    function listNewItem(uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        require(token.balanceOf(msg.sender) > 0, "Insufficient token balance");

        items.push(Item({
            seller: msg.sender,
            price: price,
            isAvailable: true
        }));

        emit ItemListed(items.length - 1, msg.sender, price);
    }

    function buyItem(uint256 itemId) external itemExists(itemId) {
        require(items[itemId].isAvailable, "Item is not available");
        require(token.balanceOf(msg.sender) >= items[itemId].price, "Insufficient token balance");

        address seller = items[itemId].seller;
        uint256 price = items[itemId].price;

        token.transferFrom(msg.sender, seller, price);

        items[itemId].isAvailable = false;

        emit ItemSold(itemId, msg.sender, seller, price);
    }

    function getItemInfo(uint256 itemId) external view itemExists(itemId) returns (address seller, uint256 price, bool isAvailable) {
        Item memory item = items[itemId];
        return (item.seller, item.price, item.isAvailable);
    }
}
