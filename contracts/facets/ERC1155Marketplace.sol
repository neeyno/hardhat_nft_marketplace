// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {IERC1155Marketplace} from "../interfaces/IERC1155Marketplace.sol";
import {LibNFTUtils, Modifiers} from "../libraries/LibNFTUtils.sol";
import {AppStorage, Listing1155} from "../libraries/LibAppStorage.sol";
import {LibERC1155Market as Lib} from "../libraries/LibERC1155Market.sol";
import "../libraries/Errors.sol";

contract ERC1155Marketplace is IERC1155Marketplace, Modifiers {
    using LibNFTUtils for address;

    // External functions
    function listERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external validValue(quantity) validValue(price) {
        Lib.requireSufficientBalance(
            msg.sender,
            nftContract,
            tokenId,
            quantity
        );

        // check item is approved for the marketplace
        Lib.requireIsApprovedForAll(msg.sender, address(this), nftContract);

        Listing1155 memory listing = AppStorage.layout().listings1155[
            nftContract
        ][tokenId];

        // check item is not listed
        if (listing.price > 0 || listing.seller != address(0)) {
            revert NFTMarket__ItemAlreadyListed();
        }

        // create new item for the listing
        AppStorage.layout().listings1155[nftContract][tokenId] = Listing1155(
            msg.sender,
            price,
            quantity
        );

        emit ERC1155ItemListed(
            msg.sender,
            nftContract,
            tokenId,
            quantity,
            price
        );
    }

    function buyERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) external payable validValue(quantity) {
        AppStorage.StorageLayout storage sl = AppStorage.layout();
        Listing1155 memory listedItem = sl.listings1155[nftContract][tokenId];

        Lib.requireIsListed(listedItem.price);

        uint256 totalPrice = listedItem.price * quantity;

        if (msg.value < totalPrice) {
            revert NFTMarket__PriceNotMet(msg.value, totalPrice);
        }

        if (quantity > listedItem.quantity) {
            revert NFTMarket__InsufficientQuantity();
        }

        uint256 remainingQuantity = listedItem.quantity - quantity;

        if (remainingQuantity == 0) {
            delete sl.listings1155[nftContract][tokenId];
        } else {
            sl.listings1155[nftContract][tokenId].quantity = remainingQuantity;
        }

        // calculate Royalty
        bytes memory royaltyData = nftContract.callRoyalty(tokenId, msg.value);

        if (royaltyData.length != 0) {
            (address royaltyReceiver, uint256 royaltyAmount) = abi.decode(
                royaltyData,
                (address, uint256)
            );

            if (/* royaltyReceiver != address(0) && */ royaltyAmount != 0) {
                // set royalty fee to collection owner
                unchecked {
                    sl.profits[royaltyReceiver] += royaltyAmount;
                }
            }

            // check royalty amount manipulation
            uint256 sellerTotal = msg.value - royaltyAmount;
            unchecked {
                sl.profits[listedItem.seller] += sellerTotal;
            }
            //
        } else {
            unchecked {
                sl.profits[listedItem.seller] += msg.value;
            }
        }

        // Trasfer NFT from seller
        Lib.requireIsApprovedForAll(msg.sender, address(this), nftContract);

        bytes memory resultData = (listedItem.seller).sendNFTs(
            msg.sender,
            nftContract,
            tokenId,
            quantity
        );

        emit ERC1155ItemBought(
            msg.sender,
            nftContract,
            tokenId,
            quantity,
            msg.value,
            resultData
        );
    }

    function updateERC1155Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external validValue(newPrice) {
        Listing1155 memory listedItem = AppStorage.layout().listings1155[
            nftContract
        ][tokenId];

        Lib.requireIsOwner(msg.sender, listedItem.seller);

        Lib.requireIsListed(listedItem.price);

        AppStorage.layout().listings1155[nftContract][tokenId].price = newPrice;

        emit ERC1155ItemListed(msg.sender, nftContract, tokenId, 0, newPrice);
    }

    function cancelERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external {
        Listing1155 memory listedItem = AppStorage.layout().listings1155[
            nftContract
        ][tokenId];

        Lib.requireIsOwner(msg.sender, listedItem.seller);

        Lib.requireIsListed(listedItem.price);

        delete (AppStorage.layout().listings1155[nftContract][tokenId]);

        emit ERC1155ItemDelisted(msg.sender, nftContract, tokenId);
    }

    function getERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing1155 memory) {
        return AppStorage.layout().listings1155[nftContract][tokenId];
    }
}

/* 
    function withdrawProfits() external returns (bool) { 
        uint256 profits = AppStorage.layout().profits[msg.sender];
        if (profits == 0) revert NFTMarket__NoProfits();

        AppStorage.layout().profits[msg.sender] = 0;

        (bool success, bytes memory data) = payable(msg.sender).call{
            value: profits
        }("");

        if (!success) revert NFTMarket__TransferFailed(data);
        return success;
    }

    function getListing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing memory) {
        // Listing memory listedItem = _listings[nftContract][tokenId];
        // (listedItem).requireIsListed();
        return _listings[nftContract][tokenId];
    }

    function getProfits(address seller) external view returns (uint256) {
        return _profits[seller];
    } 
    */
