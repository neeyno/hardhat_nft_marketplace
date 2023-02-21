// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import "hardhat/console.sol";

import {INFTMarketplace} from "./interfaces/INFTMarketplace.sol";
import "./libraries/LibNFTMarketplace.sol";

contract NFTMarketplace is INFTMarketplace, Modifiers {
    using NFTMarketAddress for address;

    /* State Variables */

    // Mapping from NFT contract address from token ID to Listing
    mapping(address => mapping(uint256 => Listing)) private _listings;

    // Mapping seller address to amount earned
    mapping(address => uint256) private _proceeds;

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

    function cancelListing(
        address nftContract,
        uint256 tokenId
    ) external override {
        (msg.sender).requireIsOwner(nftContract, tokenId);

        requireIsListed(_listings[nftContract][tokenId]);

        delete (_listings[nftContract][tokenId]);

        emit ItemDelisted(msg.sender, nftContract, tokenId);
    }

    function buyItem(
        address nftContract,
        uint256 tokenId
    ) external payable override validValue(msg.value) /* noReentrant*/ {
        Listing memory listedItem = _listings[nftContract][tokenId];

        requireIsListed(listedItem);

        if (msg.value < listedItem.price) {
            revert NFTMarket__PriceNotMet(msg.value, listedItem.price);
        }

        delete _listings[nftContract][tokenId];

        unchecked {
            _proceeds[listedItem.seller] += msg.value;
        }

        address(this).requireIsApproved(nftContract, tokenId);

        (bool success, bytes memory returnData) = nftContract.call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                listedItem.seller,
                msg.sender,
                tokenId
            )
        );

        (nftContract).verifyCallResult(success, returnData);

        emit ItemBought(
            msg.sender,
            nftContract,
            tokenId,
            msg.value,
            returnData
        );
    }

    function updatePrice(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external override validValue(newPrice) {
        (msg.sender).requireIsOwner(nftContract, tokenId);

        requireIsListed(_listings[nftContract][tokenId]);

        _listings[nftContract][tokenId].price = newPrice;

        emit ItemListed(msg.sender, nftContract, tokenId, newPrice);
    }

    function getListing(
        address nftContract,
        uint256 tokenId
    ) external view override returns (Listing memory) {
        return _listings[nftContract][tokenId];
    }

    function getProceeds(
        address seller
    ) external view override returns (uint256) {
        return _proceeds[seller];
    }

    // Public visible functions
    // Internal visible functions
    // Private visible functions
}
