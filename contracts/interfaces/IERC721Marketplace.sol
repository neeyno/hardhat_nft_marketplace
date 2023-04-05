// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title ERC721Marketplace interface
 */
interface IERC721Marketplace {
    /**
     * @notice Emitted when an ERC721 item (`nftContract`, `tokenId`) owned by `seller` is listed to the marketplace with `price`.
     * Emitted when `price` updates
     */
    event ERC721ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @notice Emitted when an ERC721 item (`nftContract`, `tokenId`) is bought by `buyer` with `price`.
     * Returns result data `returnData` when trasfers NFT.
     */
    event ERC721ItemBought(
        address indexed seller,
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        bytes returnData
    );

    /**
     * @notice Emitted when an ERC721 item (`nftContract`, `tokenId`) owned by `seller` is updated with new params.
     */
    event ERC721ItemUpdated(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    /**
     * @notice Emitted when an ERC721 item (`nftContract`, `tokenId`) owned by `seller` is delisted from the marketplace.
     */
    event ERC721ItemDelisted(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId
    );

    /**
     * @notice Method for listing ERC721 NFT
     * @param nftContract Address of ERC721 NFT contract
     * @param tokenId Token ID of NFT
     * @param price sale price for each item
     */
    function listERC721Item(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external;

    /**
     * @notice Method for buying ERC721 listing
     * @param nftContract Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function buyERC721Item(
        address nftContract,
        uint256 tokenId
    ) external payable;

    /**
     * @notice Method for updating ERC721 listing
     * @param nftContract Address of ERC721 NFT contract
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item
     */
    function updateERC721Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external;

    /**
     * @notice Method for cancelling ERC721 listing
     * @param nftContract Address of ERC721 NFT contract
     * @param tokenId Token ID of NFT
     */
    function cancelERC721Listing(address nftContract, uint256 tokenId) external;
}
