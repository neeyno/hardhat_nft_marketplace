// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface INFTMarketBase {
    event MarketWithdrawal(uint256 amount, bytes data);

    function withdrawProfits() external returns (bool);

    function getProfits(address account) external view returns (uint256);
}
