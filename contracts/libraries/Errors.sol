// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

error NFTMarket__NotApprovedForMarketplace();
error NFTMarket__ItemAlreadyListed();
error NFTMarket__ItemNotListed();
error NFTMarket__NotOwner();
error NFTMarket__PriceNotMet(uint256 msgValue, uint256 price);
error NFTMarket__NoProfits();
error NFTMarket__FailedTransfer();
error NFTMarket__ZeroValue();
error NFTMarket__CallFailed(bytes data);
error NFTMarket__TransferFailed(bytes data);
