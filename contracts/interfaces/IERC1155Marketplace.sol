// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title ERC1155Marketplace interface
 */
interface IERC1155Marketplace {
    /**
     * @notice Emitted when an ERC1155 items(`nftContract`, `tokenId`, `quantity`)
     * owned by `seller` are listed to the marketplace with `price`.
     *
     * Emitted when `price` updates
     */
    event ERC1155ItemListed(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    );

    /**
     * @notice Emitted when an ERC1155 items(`nftContract`, `tokenId`, `quantity`)
     * are bought by `buyer` with `price`.
     *
     * Returns result data `returnData` when transfers NFT.
     */
    event ERC1155ItemBought(
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        bytes returnData
    );

    /**
     * @notice Emitted when an ERC1155 items (`nftContract`, `tokenId`, `quantity`)
     * owned by `seller` are delisted from the marketplace.
     */
    event ERC1155ItemDelisted(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId
    );

    event ERC1155ItemUpdated(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 newPrice
    );

    /**
     * @notice Method for listing ERC1155 NFT
     * @param nftContract Address of ERC1155 NFT contract
     * @param tokenId Token ID of NFT
     * @param quantity Quantity of tokens to list
     * @param price Selling price sale price for each item
     *
     * Emits an {ERC1155ItemListed} event.
     */
    function listERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external;

    /**
     * @notice Method for buying ERC1155 listing
     * @param nftContract Address of ERC1155 NFT contract
     * @param tokenId Token ID of NFT
     * @param quantity Quantity of tokens to buy
     *
     * Emits an {ERC1155ItemBought} event.
     */
    function buyERC1155Item(
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) external payable;

    /**
     * @notice Method for updating ERC1155 listing
     * @param nftContract Address of ERC1155 NFT contract
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item to update
     *
     * Emits an {ERC1155ItemListed} event.
     */
    function updateERC1155Price(
        address nftContract,
        uint256 tokenId,
        uint256 newPrice
    ) external;

    /**
     * @notice Method for cancelling ERC1155 listing
     * @param nftContract Address of ERC1155 NFT contract
     * @param tokenId Token ID of NFT
     *
     * Emits an {ERC1155ItemDelisted} event.
     */
    function cancelERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external;
}
