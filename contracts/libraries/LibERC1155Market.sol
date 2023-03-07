// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC1155} from "../interfaces/IERC1155.sol";
import {Listing1155} from "./LibAppStorage.sol";
import "./Errors.sol";

library LibERC1155Market {
    function requireSufficientBalance(
        address account,
        address nftContract,
        uint256 tokenId
    ) internal view {
        if (IERC1155(nftContract).balanceOf(account, tokenId) < 1) {
            revert NFTMarket__InsufficientBalance();
        }
    }

    function requireSufficientBalance(
        address account,
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) internal view {
        if (IERC1155(nftContract).balanceOf(account, tokenId) < quantity) {
            revert NFTMarket__InsufficientBalance();
        }
    }

    function requireIsApprovedForAll(
        address account,
        address operator,
        address nftContract
    ) internal view {
        if (IERC1155(nftContract).isApprovedForAll(account, operator) != true) {
            revert NFTMarket__NotApprovedForMarketplace();
        }
    }

    function requireIsOwner(address account, address seller) internal pure {
        if (account != seller) {
            revert NFTMarket__NotOwner();
        }
    }

    function requireIsListed(uint256 price) internal pure {
        if (price == 0) {
            revert NFTMarket__ItemNotListed();
        }
    }
}
