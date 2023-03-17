// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Errors.sol";

library LibNFTUtils {
    function sendNFT(
        address from,
        address to,
        address nftContract,
        uint256 tokenId
    ) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = nftContract.call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256)",
                from,
                to,
                tokenId
            )
        );

        return verifyCallResult(nftContract, success, returnData);
    }

    function sendNFTs(
        address from,
        address to,
        address nftContract,
        uint256 tokenId,
        uint256 quantity
    ) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = nftContract.call(
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)",
                from,
                to,
                tokenId,
                quantity,
                ""
            )
        );

        return verifyCallResult(nftContract, success, returnData);
    }

    function callRoyalty(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returnData) = nftContract.staticcall(
            abi.encodeWithSignature(
                "royaltyInfo(uint256,uint256)",
                tokenId,
                price
            )
        );

        if (!success || returnData.length == 0) return "";

        return returnData;
    }

    function isContract(address account) private view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function verifyCallResult(
        address account,
        bool success,
        bytes memory returndata
    ) private view returns (bytes memory) {
        if (!success) {
            revert NFTMarket__NFTTransferFailed(returndata);
        }
        if (returndata.length == 0 && !isContract(account)) {
            // only check isContract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            revert NFTMarket__NFTTransferFailed(returndata);
        }
        return returndata;
    }
}
