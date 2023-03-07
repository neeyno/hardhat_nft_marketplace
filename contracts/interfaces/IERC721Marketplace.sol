// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Listing721} from "../libraries/LibAppStorage.sol";

interface IERC721Marketplace {
    // Events
    /**
     * @dev Emitted when `nftAddress` `tokenId` token from `seller` with `price` is listed to the marketplace.
     */
    event ERC721ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price
    );
    event ERC721ItemBought(
        address indexed buyer,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        bytes returnData
    );
    event ERC721ItemDelisted(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    function listERC721Item(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external;

    function buyERC721Item(
        address nftContract,
        uint256 tokenId
    ) external payable;

    function updateERC721Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external;

    function cancelERC721Listing(address nftContract, uint256 tokenId) external;

    function getERC721Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing721 memory);
}
