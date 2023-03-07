// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {IERC721Marketplace} from "../interfaces/IERC721Marketplace.sol";
import {LibNFTUtils, Modifiers} from "../libraries/LibNFTUtils.sol";
import {AppStorage, Listing721} from "../libraries/LibAppStorage.sol";
import {LibERC721Market as Lib} from "../libraries/LibERC721Market.sol";
import "../libraries/Errors.sol";

abstract contract ERC721Marketplace is IERC721Marketplace, Modifiers {
    using LibNFTUtils for address;

    //External functions

    function listItem721(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external validValue(price) {
        Lib.requireIsOwner(msg.sender, nftContract, tokenId);

        // check item is approved for the marketplace
        Lib.requireIsApproved(address(this), nftContract, tokenId);

        Listing721 memory listing = AppStorage.layout().listings721[
            nftContract
        ][tokenId];

        // check item is not listed
        if (listing.price > 0 || listing.seller != address(0)) {
            revert NFTMarket__ItemAlreadyListed();
        }

        // create new item for the listing
        AppStorage.layout().listings721[nftContract][tokenId] = Listing721(
            msg.sender,
            price
        );

        emit ERC721ItemListed(msg.sender, nftContract, tokenId, price);
    }

    function buyItem(address nftContract, uint256 tokenId) external payable {
        AppStorage.StorageLayout storage sl = AppStorage.layout();
        Listing721 memory listedItem = sl.listings721[nftContract][tokenId];

        Lib.requireIsListed(listedItem);

        if (msg.value < listedItem.price) {
            revert NFTMarket__PriceNotMet(msg.value, listedItem.price);
        }

        delete sl.listings721[nftContract][tokenId];

        // calculate Royalty
        bytes memory royaltyData = nftContract.callRoyalty(tokenId, msg.value);

        if (royaltyData.length != 0) {
            (address royaltyReceiver, uint256 royaltyAmount) = abi.decode(
                royaltyData,
                (address, uint256)
            );

            if (/* royaltyReceiver != address(0) && */ royaltyAmount != 0) {
                // Transfer royalty fee to collection owner
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
        Lib.requireIsApproved(address(this), nftContract, tokenId);
        bytes memory resultData = (listedItem.seller).sendNFT(
            msg.sender,
            nftContract,
            tokenId
        );

        emit ERC721ItemBought(
            msg.sender,
            nftContract,
            tokenId,
            msg.value,
            resultData
        );
    }

    function updatePrice(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external validValue(newPrice) {
        Lib.requireIsOwner(msg.sender, nftContract, tokenId);

        Lib.requireIsListed(
            AppStorage.layout().listings721[nftContract][tokenId]
        );

        AppStorage.layout().listings721[nftContract][tokenId].price = newPrice;

        emit ERC721ItemListed(msg.sender, nftContract, tokenId, newPrice);
    }

    function cancelListing(address nftContract, uint256 tokenId) external {
        Lib.requireIsOwner(msg.sender, nftContract, tokenId);

        Lib.requireIsListed(
            AppStorage.layout().listings721[nftContract][tokenId]
        );

        delete (AppStorage.layout().listings721[nftContract][tokenId]);

        emit ERC721ItemDelisted(msg.sender, nftContract, tokenId);
    }

    function getListing721(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing721 memory) {
        // Listing memory listedItem = _listings[nftContract][tokenId];
        // (listedItem).requireIsListed();
        return AppStorage.layout().listings721[nftContract][tokenId];
    }
}
