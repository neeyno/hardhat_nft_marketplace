// import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { expect } from "chai"
import { ethers, deployments, network } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { BigNumber } from "ethers"
import {
    NFTMarketBase,
    MyRoyaltyNFT,
    SimpleNFT,
    ERC721Marketplace,
    SimpleNFT1155,
    ERC1155Marketplace,
} from "../../typechain-types"

const toWei = (value: number) => ethers.utils.parseEther(value.toString()) // toWei(1) = 10e18 wei
const fromWei = (value: BigNumber) => ethers.utils.formatEther(value) // fromWei(10e18) = "1" eth

if (!developmentChains.includes(network.name)) {
    console.log("skip unit test")
    describe.skip
} else {
    describe("Marketplace Base unit test", function () {
        let [owner, alice, bob]: SignerWithAddress[] = []
        let erc721market: ERC721Marketplace
        let erc1155market: ERC1155Marketplace
        let simpleNFT: SimpleNFT
        let simpleNFT1155: SimpleNFT1155
        let market: NFTMarketBase

        before(async function () {
            const accounts = await ethers.getSigners()
            ;[owner, alice, bob] = accounts
        })

        beforeEach(async function () {
            await deployments.fixture(["diamond", "base", "erc721", "erc1155"])
            const diamond = await ethers.getContract("NFTMarketDiamond")

            market = await ethers.getContractAt(
                "NFTMarketBase",
                diamond.address,
                owner
            )

            erc721market = await ethers.getContractAt(
                "ERC721Marketplace",
                diamond.address,
                owner
            )
            erc1155market = await ethers.getContractAt(
                "ERC1155Marketplace",
                diamond.address,
                owner
            )

            simpleNFT = await ethers.getContract("SimpleNFT", owner)
            simpleNFT1155 = await ethers.getContract("SimpleNFT1155", owner)
        })

        describe("withdrawing profits", function () {
            beforeEach(async function () {
                await simpleNFT.mint(owner.address) // mints nft with tokenId: 0
                await simpleNFT.approve(erc721market.address, 0)
                await erc721market.listERC721Item(
                    simpleNFT.address,
                    0,
                    toWei(1)
                )

                await erc721market
                    .connect(alice)
                    .buyERC721Item(simpleNFT.address, 0, { value: toWei(1) })
            })

            it("should allow withdrawing profits", async function () {
                // Add some profits to the owner

                const bobBalanceBefore = await ethers.provider.getBalance(
                    bob.address
                )

                // Make sure owner has some profits
                expect(await market.profitOf(owner.address)).to.equal(toWei(1))

                // Withdraw profits to bob
                await market.withdrawProfits(bob.address)

                // Make sure bob received the profits

                const bobBalanceAfter = await ethers.provider.getBalance(
                    bob.address
                )

                expect(bobBalanceAfter).to.be.equal(
                    bobBalanceBefore.add(toWei(1))
                )
            })

            it("emits event - MarketWithdrawal", async function () {
                await expect(market.withdrawProfits(alice.address))
                    .to.emit(market, "MarketWithdrawal")
                    .withArgs(owner.address, alice.address, toWei(1), "0x")
            })
        })

        describe("listing getters", function () {
            it("should return the correct ERC721 listing", async function () {
                // Set up a test listing
                await simpleNFT.mint(owner.address) // mints nft with tokenId: 0
                await simpleNFT.approve(erc721market.address, 0)
                await erc721market.listERC721Item(
                    simpleNFT.address,
                    0,
                    toWei(0.5)
                )

                // Make sure the listing is returned correctly
                const result = await market.getERC721Listing(
                    simpleNFT.address,
                    0
                )
                expect(result.seller).to.equal(owner.address)
                expect(result.price).to.equal(toWei(0.5))
            })

            it("should return the correct ERC1155 listing", async function () {
                // Set up a test listing
                await simpleNFT1155.mint(owner.address, 123, 9, "0x") // mints nft with tokenId: 0
                await simpleNFT1155.setApprovalForAll(
                    erc1155market.address,
                    true
                )
                await erc1155market.listERC1155Item(
                    simpleNFT1155.address,
                    123,
                    9,
                    toWei(0.25)
                )

                // Make sure the listing is returned correctly
                const result = await market.getERC1155Listing(
                    simpleNFT1155.address,
                    123
                )

                expect(result.seller).to.equal(owner.address)
                expect(result.quantity).to.equal(9)
                expect(result.price).to.equal(toWei(0.25))
            })
        })

        //  describe("seller is able to withdraw profits", function () {
        //     beforeEach(async function () {
        //         await simpleNFT.mint(deployer.address) // mints nft with tokenId: 0
        //         await simpleNFT.approve(erc721market.address, 0)
        //         await erc721market.listERC721Item(
        //             simpleNFT.address,
        //             0,
        //             toWei(1)
        //         )
        //         await erc721market
        //             .connect(buyer)
        //             .buyERC721Item(simpleNFT.address, 0, { value: toWei(1) })
        //     })

        //     it("withdraws seller's profits", async function () {
        //         const sellerBalanceBefore = await ethers.provider.getBalance(
        //             deployer.address
        //         )

        //         const tx = await market.withdrawProfits(deployer.address)
        //         const txReceipt = await tx.wait()
        //         const { effectiveGasPrice, gasUsed } = txReceipt

        //         const sellerBalanceAfter = await ethers.provider.getBalance(
        //             deployer.address
        //         )

        //         const estimatedBalance = sellerBalanceBefore
        //             .sub(effectiveGasPrice.mul(gasUsed))
        //             .add(toWei(1))

        //         expect(sellerBalanceAfter).to.eq(estimatedBalance)
        //     })

        // })
    })
}
