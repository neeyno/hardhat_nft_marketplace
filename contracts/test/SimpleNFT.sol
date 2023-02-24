// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleNFT is ERC721 {
    string private constant TOKEN_URI =
        "ipfs://QmSVQf1dxZCLg6N9z19bWWkJxzQaoRJmqiTrfYBi5mbr42";
    uint256 private _tokenCounter;

    constructor() ERC721("Simple NFT", "SNT") {
        _tokenCounter = 0;
    }

    function mint(address to) external returns (uint256) {
        uint256 newTokenId = _tokenCounter;
        unchecked {
            _tokenCounter = newTokenId + 1;
        }
        _safeMint(to, newTokenId);

        return newTokenId;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return TOKEN_URI;
    }
}
