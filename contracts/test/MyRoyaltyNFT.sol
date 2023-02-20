// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract MyRoyaltyNFT is ERC2981, ERC721 {
    using Strings for uint256;
    using Base64 for bytes;

    string private constant BASE64_jsonPrefix = "data:application/json;base64,";
    string private constant TOKEN_URI =
        "ipfs://QmSVQf1dxZCLg6N9z19bWWkJxzQaoRJmqiTrfYBi5mbr42";

    uint256 private _tokenCounter;

    constructor() ERC721("My Royalty NFT", "MRN") {
        _tokenCounter = 0;
        _setDefaultRoyalty(msg.sender, 5000);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC2981, ERC721) returns (bool) {
        // ERC2981 InterfaceId = "0x2a55205a"
        // ERC721 InterfaceId = "0x80ac58cd"
        // ERC165 InterfaceId = "0x01ffc9a7"
        return super.supportsInterface(interfaceId);
    }

    function mintNFT(address to) external returns (uint256) {
        uint256 newTokenId = _tokenCounter;
        _tokenCounter = newTokenId + 1;
        _safeMint(to, newTokenId);
        _setTokenRoyalty(newTokenId, to, 100); // 100 = 1 % royalty
        return newTokenId;
    }

    function tokenURI(
        uint256 tokenId
    ) public pure override returns (string memory) {
        // string.concat("str1","str2"); ?
        // abi.encodePacked("str1","str2"); ?
        return
            string.concat(
                BASE64_jsonPrefix,
                bytes(
                    string.concat(
                        "{'name':'NFToken #",
                        tokenId.toString(),
                        "', 'description': 'Basic NFT collection', ",
                        "'attributes': [{'trait_type': 'Rarity', 'value': '1/1'}], 'image':'",
                        TOKEN_URI,
                        "'}"
                    )
                ).encode()
            );
    }

    function getTokenCounter() external view returns (uint256) {
        return _tokenCounter;
    }
}
