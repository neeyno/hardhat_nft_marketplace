// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract MyRoyaltyNFT is ERC2981, ERC721 {
    using Strings for uint256;

    string private constant BASE64_jsonPrefix = "data:application/json;base64,";
    string private constant TOKEN_URI =
        "ipfs://QmSVQf1dxZCLg6N9z19bWWkJxzQaoRJmqiTrfYBi5mbr42";

    uint256 private _tokenCounter;

    constructor() ERC721("My Royalty NFT", "MRN") {
        _tokenCounter = 0;
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
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mintNFT() external returns (uint256) {
        _tokenCounter = _tokenCounter + 1;
        _safeMint(msg.sender, _tokenCounter);
        return _tokenCounter;
    }

    function tokenURI(
        uint256 tokenId
    ) public pure override returns (string memory) {
        // return TOKEN_URI;
        return
            string(
                abi.encodePacked(
                    BASE64_jsonPrefix,
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"NFToken #',
                                tokenId.toString(),
                                '", "description": "Basic NFT collection", ',
                                '"attributes": [{"trait_type": "Rarity", "value": "1/1"}], "image":"',
                                TOKEN_URI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getTokenCounter() external view returns (uint256) {
        return _tokenCounter;
    }
}
