// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import {IERC721} from "../interfaces/IERC721.sol";

/* Type declaraton */
struct Listing {
    address seller;
    uint256 price;
}

library LibNFTMarket {
    function requireIsOwner(
        address account,
        address nftContract,
        uint256 tokenId
    ) internal view {
        if (IERC721(nftContract).ownerOf(tokenId) != account) {
            revert NFTMarket__NotOwner();
        }
    }

    function requireIsApproved(
        address target,
        address nftContract,
        uint256 tokenId
    ) internal view {
        if (IERC721(nftContract).getApproved(tokenId) != target) {
            revert NFTMarket__NotApprovedForMarketplace();
        }
    }

    function requireIsListed(Listing memory item) internal pure {
        if (item.price == 0) {
            revert NFTMarket__ItemNotListed();
        }
    }

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

    function calculateRoyalty(
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

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function verifyCallResult(
        address target,
        bool success,
        bytes memory returndata
    ) private view returns (bytes memory) {
        if (!success) {
            revert NFTMarket__CallFailed(returndata);
        }
        if (returndata.length == 0 && !isContract(target)) {
            // only check isContract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            revert NFTMarket__CallFailed(returndata);
        }
        return returndata;
    }
}

abstract contract Modifiers {
    /* Modifiers */
    modifier validValue(uint256 value) {
        if (value == 0) {
            revert NFTMarket__ZeroValue();
        }
        _;
    }
}

error NFTMarket__NotApprovedForMarketplace();
error NFTMarket__ItemAlreadyListed();
error NFTMarket__ItemNotListed();
error NFTMarket__NotOwner();
error NFTMarket__PriceNotMet(uint256 msgValue, uint256 price);
// error NFTMarket__NoReentrancy();
error NFTMarket__NoProceeds();
error NFTMarket__FailedTransfer();
error NFTMarket__ZeroValue();
error NFTMarket__CallFailed(bytes data);
error NFTMarket__TransferFailed(bytes data);

//library LibNFTMarketplace {
// function verifyCallResult(
//     address target,
//     bool success,
//     bytes memory returndata
// ) internal view returns (bool) {
//     if (!success) {
//         return false;
//     }
//     if (returndata.length == 0) {
//         // only check isContract if the call was successful and the return data is empty
//         // otherwise we already know that it was a contract
//         return isContract(target);
//     }
//     return true;
// }

// function _requireIsOwner(
//     address nftContract,
//     uint256 tokenId
// ) internal view {
//     if (IERC721(nftContract).ownerOf(tokenId) != msg.sender) {
//         revert NFTMarket__NotOwner();
//     }
// }

// function _requireIsListed(Listing memory item) internal pure {
//     if (item.price == 0) {
//         revert NFTMarket__ItemNotListed();
//     }
// }
//}
