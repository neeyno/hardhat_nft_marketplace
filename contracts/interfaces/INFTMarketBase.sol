// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Listing721, Listing1155} from "../libraries/LibAppStorage.sol";

/**
 * @title NFTMarketBase interface
 */
interface INFTMarketBase {
    event MarketWithdrawal(uint256 amount, bytes data);

    /**
     * @notice transfer account's eth balance to `to` address
     * @return whether transfer was successful or not
     */
    function withdrawProfits(address to) external returns (bool);

    /**
     * @notice query the balance of given account held by given address
     * @param account address to query
     * @return amount of profit earned by given account
     */
    function profitOf(address account) external view returns (uint256);

    /**
     * @notice get ERC721 listing status for given item `nftContract` and `tokenId` parameters
     * @param nftContract NFT contract address to query
     * @param tokenId token ID to query
     * @return item listed to the marketplac
     */
    function getERC721Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing721 memory);

    /**
     * @notice get ERC1155 listing status for given item `nftContract` and `tokenId` parameters
     * @param nftContract NFT contract address to query
     * @param tokenId token ID to query
     * @return item listed to the marketplace
     */
    function getERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing1155 memory);
}
