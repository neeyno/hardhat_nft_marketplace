// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// ERC721 Listing type
struct Listing721 {
    address seller;
    uint256 price;
}

// ERC1155 Listing type
struct Listing1155 {
    address seller;
    uint256 price; // price per token
    uint256 quantity;
}

library AppStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("NFTMarketApp.contracts.storage.AppStorage");

    struct StorageLayout {
        // Mapping from NFT contract address from token ID to Listing
        mapping(address nftContract => mapping(uint256 tokenId => Listing721)) listings721;
        // Mapping from NFT contract address from token ID to Listing
        mapping(address nftContract => mapping(uint256 tokenId => Listing1155)) listings1155;
        // Mapping seller address to amount earned
        mapping(address account => uint256 balance) profits;
    }

    function layout() internal pure returns (StorageLayout storage sl) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            sl.slot := slot
        }
    }
}

abstract contract Modifiers {
    // Custom error for invalid input
    error NFTMarket__ZeroValue();

    // Modifiers
    modifier validValue(uint256 value) {
        if (value == 0) {
            revert NFTMarket__ZeroValue();
        }
        _;
    }
}
