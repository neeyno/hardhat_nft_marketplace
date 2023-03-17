// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {IERC721} from "../interfaces/IERC721.sol";
import {IERC721Marketplace} from "../interfaces/IERC721Marketplace.sol";
import {LibNFTUtils} from "../libraries/LibNFTUtils.sol";
import {AppStorage, Listing721, Modifiers} from "../libraries/LibAppStorage.sol";
import "../libraries/Errors.sol";

contract ERC721Marketplace is IERC721Marketplace, Modifiers {
    using LibNFTUtils for address;

    //External functions

    function listERC721Item(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external validValue(price) {
        _requireIsOwner(msg.sender, nftContract, tokenId);

        // check item is approved for the marketplace
        _requireIsApproved(address(this), nftContract, tokenId);

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

    function buyERC721Item(
        address nftContract,
        uint256 tokenId
    ) external payable {
        AppStorage.StorageLayout storage sl = AppStorage.layout();
        Listing721 memory listedItem = sl.listings721[nftContract][tokenId];

        _requireIsListed(listedItem);

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

        // _requireIsApproved(address(this), nftContract, tokenId);

        // Trasfer NFT from seller
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

    function updateERC721Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external validValue(newPrice) {
        _requireIsOwner(msg.sender, nftContract, tokenId);

        _requireIsListed(AppStorage.layout().listings721[nftContract][tokenId]);

        AppStorage.layout().listings721[nftContract][tokenId].price = newPrice;

        emit ERC721ItemListed(msg.sender, nftContract, tokenId, newPrice);
    }

    function cancelERC721Listing(
        address nftContract,
        uint256 tokenId
    ) external {
        _requireIsOwner(msg.sender, nftContract, tokenId);

        _requireIsListed(AppStorage.layout().listings721[nftContract][tokenId]);

        delete (AppStorage.layout().listings721[nftContract][tokenId]);

        emit ERC721ItemDelisted(msg.sender, nftContract, tokenId);
    }

    function _requireIsOwner(
        address account,
        address nftContract,
        uint256 tokenId
    ) private view {
        if (IERC721(nftContract).ownerOf(tokenId) != account) {
            revert NFTMarket__NotOwner();
        }
    }

    function _requireIsApproved(
        address target,
        address nftContract,
        uint256 tokenId
    ) private view {
        if (IERC721(nftContract).getApproved(tokenId) != target) {
            revert NFTMarket__NotApprovedForMarketplace();
        }
    }

    function _requireIsListed(Listing721 memory item) private pure {
        if (item.price == 0) {
            revert NFTMarket__ItemNotListed();
        }
    }
}
