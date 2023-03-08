// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

//import "hardhat/console.sol";

import {INFTMarketBase} from "../interfaces/INFTMarketBase.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";
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
}
