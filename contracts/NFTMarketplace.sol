// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import "hardhat/console.sol";

import {INFTMarketplace} from "./interfaces/INFTMarketplace.sol";
import "./libraries/LibNFTMarketplace.sol";

contract NFTMarketplace is INFTMarketplace, Modifiers {
    using LibNFTMarket for *;

    /* State Variables */
    // uint256 private constant PLATFORM_FEE = 100; // _platformFee 1%

    // Mapping from NFT contract address from token ID to Listing
    mapping(address => mapping(uint256 => Listing)) private _listings;

    // Mapping seller address to amount earned
    mapping(address => uint256) private _proceeds;

    receive() external payable {}

    /* External functions */

    // listItem_gC7(address,uint256,uint256): 0x0000db25
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

    // buyItem_CcQ(address,uint256): 0x0000c692
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
        bytes memory royaltyData = nftContract.calculateRoyalty(
            tokenId,
            msg.value
        );

        if (royaltyData.length != 0) {
            (address royaltyReceiver, uint256 royaltyAmount) = abi.decode(
                royaltyData,
                (address, uint256)
            );

            if (/* royaltyReceiver != address(0) && */ royaltyAmount != 0) {
                // Transfer royalty fee to collection owner
                unchecked {
                    _proceeds[royaltyReceiver] += royaltyAmount;
                }
            }

            // check royalty amount manipulation
            uint256 sellerTotal = msg.value - royaltyAmount;
            unchecked {
                _proceeds[listedItem.seller] += sellerTotal;
            }
            //
        } else {
            unchecked {
                _proceeds[listedItem.seller] += msg.value;
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
        uint256 proceeds = _proceeds[msg.sender];
        if (proceeds == 0) revert NFTMarket__NoProceeds();

        _proceeds[msg.sender] = 0;

        (bool success, bytes memory data) = payable(msg.sender).call{
            value: proceeds
        }("");

        if (!success) revert NFTMarket__TransferFailed(data);
        return success;
    }

    // updatePrice_yc0(address,uint256,uint256): 0x00003bcb
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

    // cancelListing_R2(address,uint256): 0x0000ff65
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

    function getProceeds(address seller) external view returns (uint256) {
        return _proceeds[seller];
    }
}
