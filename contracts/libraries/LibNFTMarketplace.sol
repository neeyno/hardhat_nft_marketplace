// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.17;

// Struct, Arrays or Enums

/*
// Type declaraton
*/
struct Listing {
    address seller;
    uint256 price;
}

library LibNFTMarket {
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
    ) internal view returns (bool) {
        if (!success) {
            return false;
        }
        if (returndata.length == 0) {
            // only check isContract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            return isContract(target);
        }
        return true;

        // if (!sent || (data.length != 0 || !abi.decode(data, (bool)))) {
        //     revert NFTMarket__safeTransferFailed();
        // }
    }

    // /**
    //  * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
    //  * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
    //  *
    //  * _Available since v4.8._
    //  */
    // function verifyCallResultFromTarget(
    //     address target,
    //     bool success,
    //     bytes memory returndata,
    //     string memory errorMessage
    // ) internal view returns (bytes memory) {
    //     if (success) {
    //         if (returndata.length == 0) {
    //             // only check isContract if the call was successful and the return data is empty
    //             // otherwise we already know that it was a contract
    //             require(isContract(target), "Address: call to non-contract");
    //         }
    //         return returndata;
    //     } else {
    //         _revert(returndata, errorMessage);
    //     }
    // }
}
