// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC721} from "../interfaces/IERC721.sol";
import {Listing721} from "./LibAppStorage.sol";
import "./Errors.sol";

library LibERC721Market {
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

    function requireIsListed(Listing721 memory item) internal pure {
        if (item.price == 0) {
            revert NFTMarket__ItemNotListed();
        }
    }
}

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
