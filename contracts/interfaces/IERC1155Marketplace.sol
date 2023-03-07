// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Listing1155} from "../libraries/LibAppStorage.sol";

interface IERC1155Marketplace {
    event ERC1155ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 price
    );
    event ERC1155ItemBought(
        address indexed buyer,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 price,
        bytes returnData
    );

    event ERC1155ItemDelisted(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId
        /* uint256 quantity */
    );

    function listERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external;

    function buyERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) external payable;

    function updateERC1155Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external;

    function cancelERC1155Listing(
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) external;

    function getERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing1155 memory);
}
