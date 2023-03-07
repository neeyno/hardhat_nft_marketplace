// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

import "hardhat/console.sol";

import {INFTMarketplace} from "./interfaces/INFTMarketplace.sol";
import {LibNFTUtils} from "./libraries/LibNFTUtils.sol";
import {LibNFTMarket, Modifiers, Listing} from "./libraries/LibNFTMarket.sol";
import "./libraries/Errors.sol";

contract NFTMarketplace is INFTMarketplace, Modifiers {
    using LibNFTUtils for address;
    using LibNFTMarket for *;

    /* State Variables */

    // Mapping from NFT contract address from token ID to Listing
    mapping(address => mapping(uint256 => Listing)) private _listings;

    // Mapping seller address to amount earned
    mapping(address => uint256) private _profits;

    /* External functions */

    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external validValue(price) {
        (msg.sender).requireIsOwner(nftContract, tokenId);

        // check item is approved for the marketplace
        address(this).requireIsApproved(nftContract, tokenId);

        Listing memory listing = _listings[nftContract][tokenId];

        // check item is not listed
        if (listing.price > 0 || listing.seller != address(0)) {
            revert NFTMarket__ItemAlreadyListed();
        }

        // create new item for the listing
        _listings[nftContract][tokenId] = Listing(msg.sender, price);

        emit ItemListed(msg.sender, nftContract, tokenId, price);
    }

    function buyItem(
        address nftContract,
        uint256 tokenId
    ) external payable /* noReentrant*/ {
        Listing memory listedItem = _listings[nftContract][tokenId];

        (listedItem).requireIsListed();

        if (msg.value < listedItem.price) {
            revert NFTMarket__PriceNotMet(msg.value, listedItem.price);
        }

        delete _listings[nftContract][tokenId];

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
                    _profits[royaltyReceiver] += royaltyAmount;
                }
            }

            // check royalty amount manipulation
            uint256 sellerTotal = msg.value - royaltyAmount;
            unchecked {
                _profits[listedItem.seller] += sellerTotal;
            }
            //
        } else {
            unchecked {
                _profits[listedItem.seller] += msg.value;
            }
        }

        // Trasfer NFT from seller
        address(this).requireIsApproved(nftContract, tokenId);
        bytes memory resultData = (listedItem.seller).sendNFT(
            msg.sender,
            nftContract,
            tokenId
        );

        emit ItemBought(
            msg.sender,
            nftContract,
            tokenId,
            msg.value,
            resultData
        );
    }

    function withdrawProfits() external returns (/* noReentrant*/ bool) {
        uint256 profits = _profits[msg.sender];
        if (profits == 0) revert NFTMarket__NoProfits();

        _profits[msg.sender] = 0;

        (bool success, bytes memory data) = payable(msg.sender).call{
            value: profits
        }("");

        if (!success) revert NFTMarket__TransferFailed(data);
        return success;
    }

    function updatePrice(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external validValue(newPrice) {
        (msg.sender).requireIsOwner(nftContract, tokenId);

        (_listings[nftContract][tokenId]).requireIsListed();

        _listings[nftContract][tokenId].price = newPrice;

        emit ItemListed(msg.sender, nftContract, tokenId, newPrice);
    }

    function cancelListing(address nftContract, uint256 tokenId) external {
        (msg.sender).requireIsOwner(nftContract, tokenId);

        (_listings[nftContract][tokenId]).requireIsListed();

        delete (_listings[nftContract][tokenId]);

        emit ItemDelisted(msg.sender, nftContract, tokenId);
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
}

// listItem_gC7(address,uint256,uint256): 0x0000db25
// buyItem_CcQ(address,uint256): 0x0000c692
// updatePrice_yc0(address,uint256,uint256): 0x00003bcb
// cancelListing_R2(address,uint256): 0x0000ff65
