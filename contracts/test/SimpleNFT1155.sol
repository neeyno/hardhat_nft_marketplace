// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SimpleNFT1155 is ERC1155 {
    constructor() ERC1155("") {}

    function uri(uint256 id) public view override returns (string memory) {
        // _exists(id);
        return "ipfs://Qmanwc7A483CLh1b82P6BnUvdfqPG7VBuRhmEwtG6Ba6aq";
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
