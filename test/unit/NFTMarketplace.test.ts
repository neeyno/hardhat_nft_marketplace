import { expect, assert } from "chai"
import { ethers, deployments, network } from "hardhat"
// import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { NFTMarketplace } from "../../typechain-types"

if (developmentChains.includes(network.name)) {
    describe("Diamond unit test", function () {
        let [deployer, player]: SignerWithAddress[] = []
        let nftMarket: NFTMarketplace
        let royaltyNft: NFTMarketplace

        before(async () => {
            const accounts = await ethers.getSigners()
            deployer = accounts[0]
            player = accounts[1]
        })

        beforeEach(async function () {
            await deployments.fixture("market")
            nftMarket = await ethers.getContract("NFTMarketplace")
            royaltyNft = await ethers.getContract("MyRoyaltyNFT")
        })

        describe("Item listng - listItem()", function () {
            beforeEach(async function () {
                await nftSample.mintNFT()
            })

            it("reverts if not approved", async function () {
                await expect(
                    nftMarket.listItem(nftAddress, tokenId, price1Eth)
                ).to.be.revertedWith(
                    "NFTMarketplace__NotApprovedForMarketplace()"
                )
            })

            it("checks that item has not been listed", async function () {
                await nftSample.approve(nftMarketplace.address, tokenId)
                await nftMarketplace.listItem(nftAddress, tokenId, price1Eth)

                await expect(
                    nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
                ).to.be.revertedWith("NFTMarketplace__ItemAlreadyListed")
            })

            it("checks the owner of the item", async function () {
                await nftSample.approve(nftMarketplace.address, tokenId)
                await expect(
                    nftMarketplace
                        .connect(accounts[1])
                        .listItem(nftAddress, tokenId, price1Eth)
                ).to.be.revertedWith("NFTMarketplace__NotOwner")
            })

            it("reverts if the price is less or equal 0", async function () {
                await nftSample.approve(nftMarketplace.address, tokenId)
                const zeroPrice = ethers.utils.parseEther("0")
                await expect(
                    nftMarketplace.listItem(nftAddress, tokenId, zeroPrice)
                ).to.be.revertedWith("NFTMarketplace__PriceMustBeAboveZero()")
            })

            it("lists the item to the marketplace", async function () {
                await nftSample.approve(nftMarketplace.address, tokenId)
                await nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
                const { price, seller } = await nftMarketplace.getListing(
                    nftAddress,
                    tokenId
                )

                assert.equal(price.toString(), price1Eth.toString())
                assert.equal(seller, deployer)
            })

            it("emits event(ItemListed)", async function () {
                await nftSample.approve(nftMarketplace.address, tokenId)
                await expect(
                    nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
                )
                    .to.emit(nftMarketplace, "ItemListed")
                    .withArgs(deployer, nftAddress, tokenId, price1Eth)
            })
        })
    })
} else {
    describe.skip
}
