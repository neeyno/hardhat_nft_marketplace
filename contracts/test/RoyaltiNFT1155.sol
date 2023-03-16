// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract RoyaltiNFT1155 is ERC2981, ERC1155 {
    constructor() ERC1155("") {
        _setDefaultRoyalty(msg.sender, 1000); // 10%
    }

    function uri(uint256 id) public pure override returns (string memory) {
        // _exists(id);
        return "ipfs://Qmanwc7A483CLh1b82P6BnUvdfqPG7VBuRhmEwtG6Ba6aq";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC2981, ERC1155) returns (bool) {
        // IERC2981 InterfaceId = "0x2a55205a"
        // IERC1155 InterfaceId = "0xd9b67a26"
        // IERC1155MetadataURI InterfaceId = "0x0e89341c"
        // interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId)
        return super.supportsInterface(interfaceId);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _mintBatch(to, ids, amounts, data);
    }
}
