// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

import {IERC721} from "../interfaces/IERC721.sol";

/* Type declaraton */
struct Listing {
    address seller;
    uint256 price;
}

library NFTMarketAddress {
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

    // function requireIsListed(Listing memory item) internal pure {
    //     if (item.price == 0) {
    //         revert NFTMarket__ItemNotListed();
    //     }
    // }

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
    ) internal view returns (bytes memory) {
        if (!success) {
            revert NFTMarket__safeTransferFailed(returndata);
        }
        if (returndata.length == 0 && !isContract(target)) {
            // only check isContract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            revert NFTMarket__safeTransferFailed(returndata);
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

    function requireIsListed(Listing memory item) internal pure {
        if (item.price == 0) {
            revert NFTMarket__ItemNotListed();
        }
    }
}

error NFTMarket__NotApprovedForMarketplace();
error NFTMarket__ItemAlreadyListed();
error NFTMarket__ItemNotListed();
error NFTMarket__NotOwner();
error NFTMarket__PriceNotMet(uint256 msgValue, uint256 price);
error NFTMarket__NoReentrancy();
error NFTMarket__NoProceeds();
error NFTMarket__FailedTransfer();
error NFTMarket__ZeroValue();
error NFTMarket__safeTransferFailed(bytes returndata);

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
