// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {IERC1155} from "../interfaces/IERC1155.sol";
import {IERC1155Marketplace} from "../interfaces/IERC1155Marketplace.sol";
import {LibNFTUtils} from "../libraries/LibNFTUtils.sol";
import {AppStorage, Listing1155, Modifiers} from "../libraries/LibAppStorage.sol";
import "../libraries/Errors.sol";

contract ERC1155Marketplace is IERC1155Marketplace, Modifiers {
    using LibNFTUtils for address;

    // External functions

    // erc1155 - rewrite previous listing if it is already listed
    function listERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external validValue(quantity) validValue(price) {
        _requireSufficientBalance(msg.sender, nftContract, tokenId, quantity);

        // check item is approved for the marketplace
        _requireIsApprovedForAll(msg.sender, address(this), nftContract);

        /* 
        Listing1155 memory listing = AppStorage.layout().listings1155[
            nftContract
        ][tokenId];

        // check item is not listed
        if (listing.price > 0 || listing.seller != address(0)) {
            revert NFTMarket__ItemAlreadyListed();
        } 
        */

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

        _requireIsListed(listedItem.price);

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

        _requireIsOwner(msg.sender, listedItem.seller);

        _requireIsListed(listedItem.price);

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

        _requireIsOwner(msg.sender, listedItem.seller);

        // _requireIsListed(listedItem.price);

        delete (AppStorage.layout().listings1155[nftContract][tokenId]);

        emit ERC1155ItemDelisted(msg.sender, nftContract, tokenId);
    }

    function _requireSufficientBalance(
        address account,
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) private view {
        if (IERC1155(nftContract).balanceOf(account, tokenId) < quantity) {
            revert NFTMarket__InsufficientBalance();
        }
    }

    function _requireIsApprovedForAll(
        address account,
        address operator,
        address nftContract
    ) private view {
        if (IERC1155(nftContract).isApprovedForAll(account, operator) != true) {
            revert NFTMarket__NotApprovedForMarketplace();
        }
    }

    function _requireIsOwner(address account, address seller) private pure {
        if (account != seller) {
            revert NFTMarket__NotOwner();
        }
    }

    function _requireIsListed(uint256 price) private pure {
        if (price == 0) {
            revert NFTMarket__ItemNotListed();
        }
    }
}
