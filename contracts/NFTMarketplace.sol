// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import "hardhat/console.sol";

import {IERC721} from "./interfaces/IERC721.sol";
import {INFTMarketplaceBase} from "./interfaces/INFTMarketplace.sol";
import {Listing, LibNFTMarket} from "./libraries/LibNFTMarketplace.sol";

contract NFTMarketplace is INFTMarketplaceBase {
    /*  
    // State Variables 
    */
    mapping(address => mapping(uint256 => Listing)) private _listings;
    mapping(address => uint256) private _proceeds; // Seller address to amount earned

    /* 
    // Modifiers 
    */
    modifier validValue(uint256 value) {
        if (value == 0) {
            revert NFTMarket__ZeroValue();
        }
        _;
    }

    // Fallback — Receive function

    /* 
    // External functions 
    */
    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external validValue(price) {
        _requireIsOwner(nftContract, tokenId);

        // check item is approved for marketplace
        if (IERC721(nftContract).getApproved(tokenId) != address(this)) {
            revert NFTMarket__NotApprovedForMarketplace();
        }

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
        /* IERC721 nft = IERC721(nftContract);
        // checks that msg.sender is onwer of the nft
        if (nft.ownerOf(tokenId) != msg.sender) {
            revert NFTMarket__NotOwner();
        } */

        _requireIsOwner(nftContract, tokenId);
        _requireIsListed(_listings[nftContract][tokenId]);

        delete (_listings[nftContract][tokenId]);
        emit ItemDelisted(msg.sender, nftContract, tokenId);
    }

    function buyItem(
        address nftContract,
        uint256 tokenId
    ) external payable override validValue(msg.value) /* noReentrant*/ {
        Listing memory listedItem = _listings[nftContract][tokenId];

        _requireIsListed(listedItem);

        if (msg.value < listedItem.price) {
            revert NFTMarket__PriceNotMet(msg.value, listedItem.price);
        }

        delete (_listings[nftContract][tokenId]);

        unchecked {
            _proceeds[listedItem.seller] += msg.value;
        }

        (bool success, bytes memory data) = nftContract.call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                listedItem.seller,
                msg.sender,
                tokenId
            )
        );

        if (!LibNFTMarket.verifyCallResult(nftContract, success, data)) {
            revert NFTMarket__safeTransferFailed(data);
        }

        emit ItemBought(msg.sender, nftContract, tokenId, msg.value);
    }

    function updatePrice(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external override validValue(newPrice) {
        _requireIsOwner(nftContract, tokenId);
        _requireIsListed(_listings[nftContract][tokenId]);

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

    function _requireIsOwner(
        address nftContract,
        uint256 tokenId
    ) private view {
        if (IERC721(nftContract).ownerOf(tokenId) != msg.sender) {
            revert NFTMarket__NotOwner();
        }
    }

    function _requireIsListed(Listing memory item) private pure {
        if (item.price == 0) {
            revert NFTMarket__ItemNotListed();
        }
    }
}
