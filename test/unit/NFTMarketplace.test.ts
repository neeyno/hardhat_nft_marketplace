// import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { expect, assert } from "chai"
import { ethers, deployments, network } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { NFTMarketplace, MyRoyaltyNFT } from "../../typechain-types"
import { BigNumber } from "ethers"

const toWei = (value: number): BigNumber =>
    ethers.utils.parseEther(value.toString()) // toWei(1) = 10e18 wei
const fromWei = (value: BigNumber): string => ethers.utils.formatEther(value) // fromWei(10e18) = 1 eth

if (!developmentChains.includes(network.name)) {
    describe.skip
}

describe("NFt Marketplace unit test", function () {
    let [deployer, user]: SignerWithAddress[] = []
    let nftMarketplace: NFTMarketplace
    let royaltyNft: MyRoyaltyNFT

    before(async function () {
        const accounts = await ethers.getSigners()
        deployer = accounts[0]
        user = accounts[1]
    })

    beforeEach(async function () {
        await deployments.fixture("all")
        nftMarketplace = await ethers.getContract("NFTMarketplace")
        royaltyNft = await ethers.getContract("MyRoyaltyNFT")
    })

    describe("Item listng - listItem()", function () {
        beforeEach(async function () {
            await royaltyNft.mintNFT(deployer.address) // mints nft with tokenId: 0
            await royaltyNft.approve(nftMarketplace.address, 0)
        })

        it("reverts if item is not approved", async function () {
            await royaltyNft.mintNFT(user.address) // mints nft tokenId: 1

            await expect(
                nftMarketplace
                    .connect(user)
                    .listItem(royaltyNft.address, 1, toWei(1))
            ).to.be.revertedWithCustomError(
                nftMarketplace,
                "NFTMarket__NotApprovedForMarketplace"
            )
        })

        it("checks that item hasn't been listed yet", async function () {
            await nftMarketplace.listItem(royaltyNft.address, 0, toWei(1))

            // try to list the same nft twice
            await expect(
                nftMarketplace.listItem(royaltyNft.address, 0, toWei(1))
            ).to.be.revertedWithCustomError(
                nftMarketplace,
                "NFTMarket__ItemAlreadyListed"
            )
        })

        it("checks the owner of the item", async function () {
            // try to list tokenId 1 from user acc
            await expect(
                nftMarketplace
                    .connect(user)
                    .listItem(royaltyNft.address, 0, toWei(1))
            ).to.be.revertedWithCustomError(
                nftMarketplace,
                "NFTMarket__NotOwner"
            )
        })

        it("reverts if the price parameter is 0", async function () {
            await expect(
                nftMarketplace.listItem(royaltyNft.address, 0, toWei(0))
            ).to.be.revertedWithCustomError(
                nftMarketplace,
                "NFTMarket__ZeroValue"
            )
        })

        it("sets a new item to the marketplace listing", async function () {
            await nftMarketplace.listItem(royaltyNft.address, 0, toWei(1))
            const { seller, price } = await nftMarketplace.getListing(
                royaltyNft.address,
                0
            )

            expect(price).to.equal(toWei(1))
            expect(seller).to.equal(deployer.address)
        })

        it("emits event - ItemListed", async function () {
            await expect(
                nftMarketplace.listItem(royaltyNft.address, 0, toWei(99))
            )
                .to.emit(nftMarketplace, "ItemListed")
                .withArgs(deployer.address, royaltyNft.address, 0, toWei(99))
        })
    })

    describe("Canceling listing - cancelListing()", function () {
        beforeEach(async function () {
            await royaltyNft.mintNFT(deployer.address)
            await royaltyNft.approve(nftMarketplace.address, 0)
            await nftMarketplace.listItem(royaltyNft.address, 0, toWei(2))
        })

        it("only owner able to cancel the listing", async function () {
            await expect(
                nftMarketplace
                    .connect(user)
                    .cancelListing(royaltyNft.address, 0)
            ).to.be.revertedWithCustomError(
                nftMarketplace,
                "NFTMarket__NotOwner"
            )
        })

        it("checks that item is listed on the marketplace", async function () {
            await royaltyNft.mintNFT(deployer.address) // tokenId 1

            await expect(
                nftMarketplace.cancelListing(royaltyNft.address, 1)
            ).to.be.revertedWithCustomError(
                nftMarketplace,
                "NFTMarket__ItemNotListed"
            )
        })

        it("removes item from the listing", async function () {
            await nftMarketplace.cancelListing(royaltyNft.address, 0)
            const { price, seller } = await nftMarketplace.getListing(
                royaltyNft.address,
                0
            )

            expect(price).to.equals(0)
            expect(seller).to.equals(ethers.constants.AddressZero)
        })

        it("emits event - ItemDelisted", async function () {
            await expect(nftMarketplace.cancelListing(royaltyNft.address, 0))
                .to.emit(nftMarketplace, "ItemDelisted")
                .withArgs(deployer.address, royaltyNft.address, 0)
        })
    })

    describe("Update listing price - updatePrice()", function () {
        beforeEach(async function () {
            await royaltyNft.mintNFT(deployer.address)
            await royaltyNft.approve(nftMarketplace.address, 0)
            await nftMarketplace.listItem(royaltyNft.address, 0, toWei(3))
        })

        it("updates listing price with new value", async function () {
            const { price: priceBefore, seller: sellerBefore } =
                await nftMarketplace.getListing(royaltyNft.address, 0)

            await nftMarketplace.updatePrice(royaltyNft.address, 0, toWei(4))

            const { price: newPrice, seller } = await nftMarketplace.getListing(
                royaltyNft.address,
                0
            )

            expect(priceBefore).to.eq(toWei(3))
            expect(newPrice).to.eq(toWei(4))
            expect(seller).to.eq(sellerBefore)
        })

        it("emits event on price update - ItemListed", async function () {
            await expect(
                nftMarketplace.updatePrice(royaltyNft.address, 0, toWei(4))
            )
                .to.emit(nftMarketplace, "ItemListed")
                .withArgs(deployer.address, royaltyNft.address, 0, toWei(4))
        })
    })

    describe("Buying item - buyItem()", function () {
        beforeEach(async function () {
            await royaltyNft.mintNFT(deployer.address)
            await royaltyNft.approve(nftMarketplace.address, 0)
            await nftMarketplace.listItem(royaltyNft.address, 0, toWei(5))
        })

        it("checks that item is listed on the marketplace", async function () {
            await expect(
                nftMarketplace.buyItem(royaltyNft.address, 2, {
                    value: toWei(0.1),
                })
            ).to.be.revertedWithCustomError(
                nftMarketplace,
                "NFTMarket__ItemNotListed"
            )
        })

        it("checks price matching", async function () {
            await expect(
                nftMarketplace.buyItem(royaltyNft.address, 0, {
                    value: toWei(0.99),
                })
            )
                .to.be.revertedWithCustomError(
                    nftMarketplace,
                    "NFTMarket__PriceNotMet"
                )
                .withArgs(toWei(0.99), toWei(5))
        })

        it("removes bought item from the listing", async function () {
            await nftMarketplace.connect(user).buyItem(royaltyNft.address, 0, {
                value: toWei(5),
            })
            const { price, seller } = await nftMarketplace.getListing(
                royaltyNft.address,
                0
            )

            expect(price).to.eq(0)
            expect(seller).to.eq(ethers.constants.AddressZero)
        })

        it("sets new proceeds to seller balance", async function () {
            const proceedsBefore = await nftMarketplace.getProceeds(
                deployer.address
            )

            await nftMarketplace.connect(user).buyItem(royaltyNft.address, 0, {
                value: toWei(5),
            })

            const proceedsAfter = await nftMarketplace.getProceeds(
                deployer.address
            )

            expect(proceedsBefore).to.eq(0)
            expect(proceedsAfter).to.eq(toWei(5))
        })

        it("transfers item to the buyer", async function () {
            await nftMarketplace.connect(user).buyItem(royaltyNft.address, 0, {
                value: toWei(5),
            })
            const newOwner = await royaltyNft.ownerOf(0)

            expect(newOwner).to.eq(user.address)
        })

        it("emits event - ItemBought", async function () {
            await expect(
                nftMarketplace.connect(user).buyItem(royaltyNft.address, 0, {
                    value: toWei(5),
                })
            )
                .to.emit(nftMarketplace, "ItemBought")
                .withArgs(user.address, royaltyNft.address, 0, toWei(5))
        })
    })
})
