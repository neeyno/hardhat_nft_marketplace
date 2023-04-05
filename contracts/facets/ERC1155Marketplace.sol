// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {IERC1155} from "../interfaces/IERC1155.sol";
import {IERC1155Marketplace} from "../interfaces/IERC1155Marketplace.sol";
import {LibNFTUtils} from "../libraries/LibNFTUtils.sol";
import {AppStorage, Listing1155, Modifiers} from "../libraries/LibAppStorage.sol";
import "../libraries/LibErrors.sol";

/**
 * @title ERC1155Marketplace contract
 *
 * @dev EIP-2535 Facet implementation of the multi-token marketplace.
 * See https://eips.ethereum.org/EIPS/eip-2535
 */
contract ERC1155Marketplace is IERC1155Marketplace, Modifiers {
    using LibNFTUtils for address;

    /**
     * @inheritdoc IERC1155Marketplace
     *
     * @dev Function call reverts if an NFT is not approved for the marketplace
     * @dev Previous existing listing would be overwritten with new `quantity` and `price` parameters
     */
    function listERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external validValue(quantity) validValue(price) {
        _requireSufficientBalance(msg.sender, nftContract, tokenId, quantity);

        // check item is approved for the marketplace
        _requireIsApprovedForAll(msg.sender, address(this), nftContract);

        Listing1155 memory listing = AppStorage.layout().listings1155[
            nftContract
        ][tokenId];

        // check item is not listed
        if (listing.price > 0 && listing.quantity == quantity) {
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

    /**
     * @inheritdoc IERC1155Marketplace
     *
     * @notice The owner of an NFT could unapprove the marketplace,
     * which would cause this function to revert
     * @notice msg.value must be greater or equal to the total price of the `quantity` items
     */
    function buyERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) external payable validValue(quantity) {
        AppStorage.StorageLayout storage sl = AppStorage.layout();
        Listing1155 memory item = sl.listings1155[nftContract][tokenId];

        // _requireIsListed(listedItem.price);
        if (item.price == 0) {
            revert NFTMarket__ItemNotListed();
        }
        if (quantity > item.quantity || item.quantity == 0) {
            revert NFTMarket__InsufficientQuantity();
        }

        uint256 totalPrice = item.price * quantity;

        if (msg.value < totalPrice) {
            revert NFTMarket__PriceNotMet(msg.value, totalPrice);
        }

        unchecked {
            uint256 remainingQuantity = item.quantity - quantity;

            if (remainingQuantity == 0) {
                delete sl.listings1155[nftContract][tokenId];
            } else {
                sl
                .listings1155[nftContract][tokenId]
                    .quantity = remainingQuantity;
            }
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
                sl.profits[item.seller] += sellerTotal;
            }
            //
        } else {
            unchecked {
                sl.profits[item.seller] += msg.value;
            }
        }

        // Trasfer NFTs to buyer
        bytes memory resultData = (item.seller).sendNFTs(
            msg.sender,
            nftContract,
            tokenId,
            quantity
        );

        emit ERC1155ItemBought(
            item.seller,
            msg.sender,
            nftContract,
            tokenId,
            quantity,
            msg.value,
            resultData
        );
    }

    /**
     * @inheritdoc IERC1155Marketplace
     */
    function updateERC1155Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external validValue(newPrice) {
        Listing1155 memory listedItem = AppStorage.layout().listings1155[
            nftContract
        ][tokenId];

        _requireIsOwner(msg.sender, listedItem.seller);

        // _requireIsListed(listedItem.price);

        AppStorage.layout().listings1155[nftContract][tokenId].price = newPrice;

        emit ERC1155ItemUpdated(msg.sender, nftContract, tokenId, newPrice);
    }

    /**
     * @inheritdoc IERC1155Marketplace
     */
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
            revert NFTMarket__NotApproved();
        }
    }

    function _requireIsOwner(address account, address seller) private pure {
        if (account != seller) {
            revert NFTMarket__NotOwner();
        }
    }

    /* 
    function _requireIsListed(Listing1155 memory item) private pure {
        if (item.price == 0 || item.seller == address(0)) {
            revert NFTMarket__ItemNotListed(); 
        }
    } 
    */
}
