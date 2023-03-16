// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {INFTMarketBase} from "../interfaces/INFTMarketBase.sol";
import {AppStorage, Listing721, Listing1155} from "../libraries/LibAppStorage.sol";
import "../libraries/Errors.sol";

contract NFTMarketBase is INFTMarketBase {
    function withdrawProfits() external returns (bool) {
        uint256 profits = AppStorage.layout().profits[msg.sender];
        if (profits == 0) revert NFTMarket__NoProfits();

        AppStorage.layout().profits[msg.sender] = 0;

        (bool success, bytes memory data) = payable(msg.sender).call{
            value: profits
        }("");

        if (!success) revert NFTMarket__TransferFailed(data);

        emit MarketWithdrawal(profits, data);
        return success;
    }

    function getProfits(address account) external view returns (uint256) {
        return AppStorage.layout().profits[account];
    }

    function getERC721Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing721 memory) {
        // Listing memory listedItem = _listings[nftContract][tokenId];
        // (listedItem).requireIsListed();
        return AppStorage.layout().listings721[nftContract][tokenId];
    }

    function getERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing1155 memory) {
        return AppStorage.layout().listings1155[nftContract][tokenId];
    }
}
