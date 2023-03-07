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
        mapping(address => mapping(uint256 => Listing721)) listings721;
        // Mapping from NFT contract address from token ID to Listing
        mapping(address => mapping(uint256 => Listing1155)) listings1155;
        // Mapping seller address to amount earned
        mapping(address => uint256) profits;
    }

    function layout() internal pure returns (StorageLayout storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}
