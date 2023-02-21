// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import {Listing} from "../libraries/LibNFTMarketplace.sol";

interface INFTMarketplace {
    /* 
    // Events 
    */
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        bytes returnData
    );
    event ItemDelisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external;

    function cancelListing(
        address nftContract,
        uint256 tokenId //isOwner(nftAddress, tokenId, msg.sender)
    ) external;

    function buyItem(address nftContract, uint256 tokenId) external payable;

    function updatePrice(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external;

    function getListing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing memory);

    function getProceeds(address seller) external view returns (uint256);
}

/* 
interface INFTMarketplaceInternal {
    error NFTMarket__NotApprovedForMarketplace();
    error NFTMarket__ItemAlreadyListed();
    error NFTMarket__ItemNotListed();
    error NFTMarket__NotOwner();
    error NFTMarket__PriceNotMet(uint256 msgValue, uint256 price);
    error NFTMarket__NoReentrancy();
    error NFTMarket__NoProceeds();
    error NFTMarket__FailedTransfer();
    error NFTMarket__ZeroValue();
    error NFTMarket__safeTransferFailed(bytes returndata);
}

interface INFTMarketplaceBase is INFTMarketplaceInternal, INFTMarketplace {}
 */
