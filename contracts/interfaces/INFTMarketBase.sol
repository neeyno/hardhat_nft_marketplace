// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Listing721, Listing1155} from "../libraries/LibAppStorage.sol";

interface INFTMarketBase {
    event MarketWithdrawal(uint256 amount, bytes data);

    function withdrawProfits() external returns (bool);

    function getProfits(address account) external view returns (uint256);

    function getERC721Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing721 memory);

    function getERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing1155 memory);
}
