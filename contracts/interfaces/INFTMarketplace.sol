// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.18;

import {Listing} from "../libraries/LibNFTMarket.sol";

interface INFTMarketplace {
    /* Events */
    /**
     * @dev Emitted when `nftAddress` `tokenId` token from `seller` with `price` is listed to the marketplace.
     */
    event ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemBought(
        address indexed buyer,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price,
        bytes returnData
    );
    event ItemDelisted(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external;

    function buyItem(address nftContract, uint256 tokenId) external payable;

    function withdrawProfits() external returns (bool);

    function updatePrice(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external;

    function cancelListing(address nftContract, uint256 tokenId) external;

    function getListing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing memory);

    function getProfits(address seller) external view returns (uint256);
}
