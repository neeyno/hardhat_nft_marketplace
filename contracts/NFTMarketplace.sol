// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error NFTMarketplace__PriceMustBeAboveZero();
error NFTMarketplace__NotApprovedForMarketplace();
error NFTMarketplace__ItemAlreadyListed(address nftAddress, uint256 tokenId);
error NFTMarketplace__ItemNotListed(address nftAddress, uint256 tokenId);
error NFTMarketplace__NotOwner();
error NFTMarketplace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error NFTMarketplace__NoReentrancy();
error NFTMarketplace__NoProceeds();
error NFTMarketplace__FailedTransfer();

/** @title NFT Marketplace contract
 * @author //
 * @notice This contract is for operating NFT marketplace
 * @dev //
 */
contract NFTMarketplace {
    /* Type declaraton */
    struct Listing {
        uint256 price;
        address seller;
    }

    event ItemListed(
        address indexed seller,
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemBought(
        address indexed buyer,
        address indexed nftContractAddress,
        uint256 indexed tokenId
    );
    event ItemDelisted(
        address indexed seller,
        address indexed nftContractAddress,
        uint256 indexed tokenId
    );

    /* State Variables */
    bool internal locked;
    // nft contract address => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds; // Seller address to amount earned

    /* Modifiers */
    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NFTMarketplace__ItemAlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NFTMarketplace__ItemNotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (owner != spender) {
            revert NFTMarketplace__NotOwner();
        }
        _;
    }

    modifier noReentrant() {
        if (locked) {
            revert NFTMarketplace__NoReentrancy();
        }
        locked = true;
        _;
        locked = false;
    }

    /* Functions */

    constructor() {
        locked = false;
    }

    /*
     * @notice This function lists nft to the marketplace
     * @param nftAddress: address of the nft contract
     * @param tokenId: the token id of the NFT
     * @param price: sale price
     */
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external notListed(nftAddress, tokenId, msg.sender) isOwner(nftAddress, tokenId, msg.sender) {
        if (price <= 0) {
            revert NFTMarketplace__PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NFTMarketplace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    /*
     * @notice This function allows any user to buy an nft from the marketplace
     */
    function buyItem(address nftAddress, uint256 tokenId)
        external
        payable
        noReentrant
        isListed(nftAddress, tokenId)
    {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert NFTMarketplace__PriceNotMet(nftAddress, tokenId, listedItem.price);
        }
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, nftAddress, tokenId);
    }

    /*
     * @notice This function deletes listed item from the marketplace
     */
    function cancelListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemDelisted(msg.sender, nftAddress, tokenId);
    }

    /*
     * @notice This function updates listed item with a new price
     * @param newPrice: new sale price
     */
    function updatePrice(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external isOwner(nftAddress, tokenId, msg.sender) isListed(nftAddress, tokenId) {
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    /*
     * @notice This function withdrawals earnings
     */
    function withdrawProceeds() external noReentrant {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NFTMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: proceeds}("");
        if (!sent) {
            revert NFTMarketplace__FailedTransfer();
        }
    }

    /* View/Pure functions */
    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}
