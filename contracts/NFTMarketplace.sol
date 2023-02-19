// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import "hardhat/console.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Listing} from "./libraries/LibNFTMarketplace.sol";
import {INFTMarketplaceBase} from "./interfaces/INFTMarketplace.sol";

contract NFTMarketplace is INFTMarketplaceBase {
    // Counter private _tokenIds;
    // Counter private _itemsSold;
    // uint256 private constant LISTING_PRICE = 0.01 ether;

    /*  
    // State Variables 
    */
    mapping(address => mapping(uint256 => Listing)) private _listings;
    mapping(address => uint256) private _proceeds; // Seller address to amount earned

    // Events

    /* 
    // Modifiers 
    */
    modifier validValue(uint256 value) {
        if (value == 0) {
            revert NFTMarket__ZeroValue();
        }
        _;
    }

    /* 
    // Constructor 
    */
    // constructor() {
    //     // locked = false;
    // }

    // Fallback — Receive function

    /* 
    // External functions 
    */
    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external override validValue(price) {
        _requireIsOwner(nftContract, tokenId);

        // check that msg.sender is the nft onwer
        // if (nft.ownerOf(tokenId) != msg.sender) {
        //     revert NFTMarket__NotOwner();
        // }
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

        IERC721(nftContract).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            tokenId
        );

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
