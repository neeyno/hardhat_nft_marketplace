// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// common ERC721 & ERC1155 errors
error NFTMarket__ItemAlreadyListed();
error NFTMarket__PriceNotMet(uint256 msgValue, uint256 price);
error NFTMarket__NotOwner();
error NFTMarket__NotApproved();
error NFTMarket__ItemNotListed();

// ERC1155 errors
error NFTMarket__InsufficientBalance();
error NFTMarket__InsufficientQuantity();
