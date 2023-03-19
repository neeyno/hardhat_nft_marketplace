// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {IERC721} from "../interfaces/IERC721.sol";
import {IERC721Marketplace} from "../interfaces/IERC721Marketplace.sol";
import {LibNFTUtils} from "../libraries/LibNFTUtils.sol";
import {AppStorage, Listing721, Modifiers} from "../libraries/LibAppStorage.sol";
import "../libraries/Errors.sol";

/**
 * @title ERC721Marketplace contract
 *
 * @dev EIP-2535 Facet implementation of the ERC721 marketplace.
 * See https://eips.ethereum.org/EIPS/eip-2535
 */
contract ERC721Marketplace is IERC721Marketplace, Modifiers {
    using LibNFTUtils for address;

    /**
     * @inheritdoc IERC721Marketplace
     *
     * @notice Function call reverts if an NFT is not approved for the marketplace
     */
    function listERC721Item(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external validValue(price) {
        // check the owner of an item
        _requireIsOwner(msg.sender, nftContract, tokenId);

        // check item is approved for the marketplace
        _requireIsApproved(address(this), nftContract, tokenId);

        Listing721 memory item = AppStorage.layout().listings721[nftContract][
            tokenId
        ];

        // check item is not listed
        if (item.price > 0 || item.seller != address(0)) {
            revert NFTMarket__ItemAlreadyListed();
        }

        // create new item for the listing
        AppStorage.layout().listings721[nftContract][tokenId] = Listing721(
            msg.sender,
            price
        );

        emit ERC721ItemListed(msg.sender, nftContract, tokenId, price);
    }

    /**
     * @inheritdoc IERC721Marketplace
     *
     * @notice The owner of an NFT could unapprove the marketplace,
     * which would cause this function to revert
     */
    function buyERC721Item(
        address nftContract,
        uint256 tokenId
    ) external payable {
        AppStorage.StorageLayout storage sl = AppStorage.layout();
        Listing721 memory item = sl.listings721[nftContract][tokenId];

        _requireIsListed(item);

        if (msg.value < item.price) {
            revert NFTMarket__PriceNotMet(msg.value, item.price);
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
                sl.profits[item.seller] += sellerTotal;
            }
            //
        } else {
            unchecked {
                sl.profits[item.seller] += msg.value;
            }
        }

        // Trasfer NFT from seller
        bytes memory resultData = (item.seller).sendNFT(
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

    /**
     * @inheritdoc IERC721Marketplace
     */
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

    /**
     * @inheritdoc IERC721Marketplace
     */
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
