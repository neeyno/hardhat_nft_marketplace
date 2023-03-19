// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {INFTMarketBase} from "../interfaces/INFTMarketBase.sol";
import {AppStorage, Listing721, Listing1155} from "../libraries/LibAppStorage.sol";
import "../libraries/Errors.sol";

/**
 * @title NFTMarketBase contract
 *
 * @dev EIP-2535 Facet implementation of the NFT marketplace base functionality.
 * See https://eips.ethereum.org/EIPS/eip-2535
 */
contract NFTMarketBase is INFTMarketBase {
    /**
     * @inheritdoc INFTMarketBase
     */
    function withdrawProfits(address to) external returns (bool) {
        uint256 senderProfit = AppStorage.layout().profits[msg.sender];
        if (senderProfit == 0) revert NFTMarket__NoProfits();

        AppStorage.layout().profits[msg.sender] = 0;

        (bool success, bytes memory data) = payable(to).call{
            value: senderProfit
        }("");

        if (!success) revert NFTMarket__TransferFailed(data);

        emit MarketWithdrawal(senderProfit, data);
        return success;
    }

    /**
     * @inheritdoc INFTMarketBase
     */
    function profitOf(address account) external view returns (uint256) {
        return AppStorage.layout().profits[account];
    }

    /**
     * @inheritdoc INFTMarketBase
     */
    function getERC721Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing721 memory) {
        return AppStorage.layout().listings721[nftContract][tokenId];
    }

    /**
     * @inheritdoc INFTMarketBase
     */
    function getERC1155Listing(
        address nftContract,
        uint256 tokenId
    ) external view returns (Listing1155 memory) {
        return AppStorage.layout().listings1155[nftContract][tokenId];
    }

    // to do --> `createOffer` functionality.
}
