// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IERC4907 {
    // Logged when the user of an NFT is changed or expires is changed
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint64 expires
    );

    /// @notice set the user and expires of an NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) external;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns (uint256);
}

contract RentableERC4907 is IERC4907, ERC721 {
    struct UserInfo {
        address user;
        uint64 expires;
    }

    string private constant TOKEN_URI =
        "ipfs://QmSVQf1dxZCLg6N9z19bWWkJxzQaoRJmqiTrfYBi5mbr42";

    mapping(uint256 => UserInfo) private _users;

    // mapping(uint256 => address) private _users;
    // mapping(uint256 => uint64) private _rentExpires;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(userOf(tokenId) == address(0), "already used");

        _users[tokenId] = UserInfo(user, expires);
        // UserInfo storage info = _users[tokenId];
        // info.user = user;
        // info.expires = expires;
        // _rentExpires[tokenId] = expires;

        emit UpdateUser(tokenId, user, expires);
    }

    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (userExpires(tokenId) > block.number) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
        // UserInfo memory user = _users[tokenId];
        // return user.expires > block.number ? user.user : address(0);
    }

    function userExpires(
        uint256 tokenId
    ) public view virtual returns (uint256) {
        return uint256(_users[tokenId].expires);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != to && _users[tokenId].user != address(0)) {
            delete _users[tokenId];

            emit UpdateUser(tokenId, address(0), 0);
        }
    }
}

contract MyRentableNFT is RentableERC4907 {
    uint256 private _tokenCounter;

    constructor() RentableERC4907("My rent NFT", "MRN") {}

    function mint(address to) external returns (uint256 tokenId) {
        unchecked {
            tokenId = ++_tokenCounter;
        }

        _safeMint(to, tokenId);
    }
}
