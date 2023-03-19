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
} from "../../typechain-types"

const toWei = (value: number) => ethers.utils.parseEther(value.toString()) // toWei(1) = 10e18 wei
const fromWei = (value: BigNumber) => ethers.utils.formatEther(value) // fromWei(10e18) = "1" eth

if (!developmentChains.includes(network.name)) {
    console.log("skip unit test")
    describe.skip
} else {
    describe("ERC721 Marketplace unit test", function () {
        let [deployer, user, buyer]: SignerWithAddress[] = []
        let erc721market: ERC721Marketplace
        let royaltyNft: MyRoyaltyNFT
        let simpleNFT: SimpleNFT
        let market: NFTMarketBase

        before(async function () {
            const accounts = await ethers.getSigners()
            ;[deployer, user, buyer] = accounts
        })

        beforeEach(async function () {
            await deployments.fixture(["diamond", "base", "erc721"])
            const diamond = await ethers.getContract("NFTMarketDiamond")

            market = await ethers.getContractAt(
                "NFTMarketBase",
                diamond.address
            )

            erc721market = await ethers.getContractAt(
                "ERC721Marketplace",
                diamond.address
            )
            royaltyNft = await ethers.getContract("MyRoyaltyNFT")
        })

        describe("Item listng - listERC721Item()", function () {
            beforeEach(async function () {
                await royaltyNft.mintNFT(deployer.address) // mints nft with tokenId: 0
                await royaltyNft.approve(erc721market.address, 0)
            })

            it("reverts if item is not approved", async function () {
                await royaltyNft.mintNFT(user.address) // mints nft tokenId: 1

                await expect(
                    erc721market
                        .connect(user)
                        .listERC721Item(royaltyNft.address, 1, toWei(1))
                ).to.be.revertedWithCustomError(
                    erc721market,
                    "NFTMarket__NotApprovedForMarketplace"
                )
            })

            it("checks that item hasn't been listed yet", async function () {
                await erc721market.listERC721Item(
                    royaltyNft.address,
                    0,
                    toWei(1)
                )

                // try to list the same nft twice
                await expect(
                    erc721market.listERC721Item(royaltyNft.address, 0, toWei(1))
                ).to.be.revertedWithCustomError(
                    erc721market,
                    "NFTMarket__ItemAlreadyListed"
                )
            })

            it("checks the owner of the item", async function () {
                // try to list tokenId 1 from user acc
                await expect(
                    erc721market
                        .connect(user)
                        .listERC721Item(royaltyNft.address, 0, toWei(1))
                ).to.be.revertedWithCustomError(
                    erc721market,
                    "NFTMarket__NotOwner"
                )
            })

            it("reverts if the price parameter is 0", async function () {
                await expect(
                    erc721market.listERC721Item(royaltyNft.address, 0, toWei(0))
                ).to.be.revertedWithCustomError(
                    erc721market,
                    "NFTMarket__ZeroValue"
                )
            })

            it("sets a new item to the marketplace listing", async function () {
                await erc721market.listERC721Item(
                    royaltyNft.address,
                    0,
                    toWei(1)
                )
                const { seller, price } = await market.getERC721Listing(
                    royaltyNft.address,
                    0
                )

                expect(price).to.equal(toWei(1))
                expect(seller).to.equal(deployer.address)
            })

            it("emits event - ERC721ItemListed", async function () {
                await expect(
                    erc721market.listERC721Item(
                        royaltyNft.address,
                        0,
                        toWei(99)
                    )
                )
                    .to.emit(erc721market, "ERC721ItemListed")
                    .withArgs(
                        deployer.address,
                        royaltyNft.address,
                        0,
                        toWei(99)
                    )
            })
        })

        describe("Canceling listing - cancelERC721Listing()", function () {
            beforeEach(async function () {
                await royaltyNft.mintNFT(deployer.address)
                await royaltyNft.approve(erc721market.address, 0)
                await erc721market.listERC721Item(
                    royaltyNft.address,
                    0,
                    toWei(2)
                )
            })

            it("only owner able to cancel the listing", async function () {
                await expect(
                    erc721market
                        .connect(user)
                        .cancelERC721Listing(royaltyNft.address, 0)
                ).to.be.revertedWithCustomError(
                    erc721market,
                    "NFTMarket__NotOwner"
                )
            })

            it("checks that item is listed on the marketplace", async function () {
                await royaltyNft.mintNFT(deployer.address) // tokenId 1

                await expect(
                    erc721market.cancelERC721Listing(royaltyNft.address, 1)
                ).to.be.revertedWithCustomError(
                    erc721market,
                    "NFTMarket__ItemNotListed"
                )
            })

            it("removes item from the listing", async function () {
                await erc721market.cancelERC721Listing(royaltyNft.address, 0)
                const { price, seller } = await market.getERC721Listing(
                    royaltyNft.address,
                    0
                )

                expect(price).to.equals(0)
                expect(seller).to.equals(ethers.constants.AddressZero)
            })

            it("emits event - ERC721ItemDelisted", async function () {
                await expect(
                    erc721market.cancelERC721Listing(royaltyNft.address, 0)
                )
                    .to.emit(erc721market, "ERC721ItemDelisted")
                    .withArgs(deployer.address, royaltyNft.address, 0)
            })
        })

        describe("Update listing price - updateERC721Price()", function () {
            beforeEach(async function () {
                await royaltyNft.mintNFT(deployer.address)
                await royaltyNft.approve(erc721market.address, 0)
                await erc721market.listERC721Item(
                    royaltyNft.address,
                    0,
                    toWei(3)
                )
            })

            it("updates listing price with new value", async function () {
                const { price: priceBefore, seller: sellerBefore } =
                    await market.getERC721Listing(royaltyNft.address, 0)

                await erc721market.updateERC721Price(
                    royaltyNft.address,
                    0,
                    toWei(4)
                )

                const { price: newPrice, seller } =
                    await market.getERC721Listing(royaltyNft.address, 0)

                expect(priceBefore).to.eq(toWei(3))
                expect(newPrice).to.eq(toWei(4))
                expect(seller).to.eq(sellerBefore)
            })

            it("emits event on price update - ERC721ItemListed", async function () {
                await expect(
                    erc721market.updateERC721Price(
                        royaltyNft.address,
                        0,
                        toWei(4)
                    )
                )
                    .to.emit(erc721market, "ERC721ItemListed")
                    .withArgs(deployer.address, royaltyNft.address, 0, toWei(4))
            })
        })

        describe("Buying item - buyERC721Item()", function () {
            beforeEach(async function () {
                await royaltyNft.mintNFT(deployer.address)
                await royaltyNft.approve(erc721market.address, 0)
                await erc721market.listERC721Item(
                    royaltyNft.address,
                    0,
                    toWei(5)
                )
            })

            it("checks that item is listed on the marketplace", async function () {
                await expect(
                    erc721market.buyERC721Item(royaltyNft.address, 2, {
                        value: toWei(0.1),
                    })
                ).to.be.revertedWithCustomError(
                    erc721market,
                    "NFTMarket__ItemNotListed"
                )
            })

            it("checks price matching", async function () {
                await expect(
                    erc721market.buyERC721Item(royaltyNft.address, 0, {
                        value: toWei(0.99),
                    })
                )
                    .to.be.revertedWithCustomError(
                        erc721market,
                        "NFTMarket__PriceNotMet"
                    )
                    .withArgs(toWei(0.99), toWei(5))
            })

            it("removes bought item from the listing", async function () {
                await erc721market
                    .connect(user)
                    .buyERC721Item(royaltyNft.address, 0, {
                        value: toWei(5),
                    })
                const { price, seller } = await market.getERC721Listing(
                    royaltyNft.address,
                    0
                )

                expect(price).to.eq(0)
                expect(seller).to.eq(ethers.constants.AddressZero)
            })

            it("sets new proceeds to seller balance", async function () {
                const proceedsBefore = await market.profitOf(deployer.address)

                await erc721market
                    .connect(user)
                    .buyERC721Item(royaltyNft.address, 0, {
                        value: toWei(5),
                    })

                const proceedsAfter = await market.profitOf(deployer.address)

                expect(proceedsBefore).to.eq(0)
                expect(proceedsAfter).to.eq(toWei(5))
            })

            it("transfers item to the buyer", async function () {
                await erc721market
                    .connect(user)
                    .buyERC721Item(royaltyNft.address, 0, {
                        value: toWei(5),
                    })
                const newOwner = await royaltyNft.ownerOf(0)

                expect(newOwner).to.eq(user.address)
            })

            it("emits event - ERC721ItemBought", async function () {
                await expect(
                    erc721market
                        .connect(user)
                        .buyERC721Item(royaltyNft.address, 0, {
                            value: toWei(5),
                        })
                )
                    .to.emit(erc721market, "ERC721ItemBought")
                    .withArgs(
                        user.address,
                        royaltyNft.address,
                        0,
                        toWei(5),
                        "0x"
                    )
            })
        })

        describe("tx fails if seller removes approval  - buyERC721Item()", function () {
            beforeEach(async function () {
                await royaltyNft.mintNFT(deployer.address)
                await royaltyNft.approve(erc721market.address, 0)
                await erc721market.listERC721Item(
                    royaltyNft.address,
                    0,
                    toWei(6)
                )
            })

            it("reverts with custom error", async function () {
                await royaltyNft.approve(ethers.constants.AddressZero, 0)

                await expect(
                    erc721market
                        .connect(user)
                        .buyERC721Item(royaltyNft.address, 0, {
                            value: toWei(6),
                        })
                ).to.be.revertedWithCustomError(
                    erc721market,
                    "NFTMarket__NFTTransferFailed"
                )
            })
            /* 
        let tx: unknown

        it("restores user balance", async function () {
            await royaltyNft.approve(ethers.constants.AddressZero, 0)
            console.log(
                (await ethers.provider.getBalance(user.address)).toString()
            )
            try {
                tx = await erc721market
                    .connect(user)
                    .buyERC721Item(royaltyNft.address, 0, {
                        value: toWei(6),
                    })
            } catch (error) {
                console.log(error)
            }
        })

        function instanceOftx(object: any): object is ContractReceipt {
            return "events" in object
        }

        after(async function () {
            console.log()
            const txReceipt = instanceOftx(tx) ? tx : await tx.wait()
            const { gasUsed, effectiveGasPrice } = txReceipt
            const gasCost = gasUsed.mul(effectiveGasPrice)
            const userBalance = await ethers.provider.getBalance(user.address)
            expect(userBalance).to.eq(toWei(10000).sub(gasCost))
        }) */
        })

        describe("Selling Royalty NFT", function () {
            beforeEach(async function () {
                await royaltyNft.mintNFT(user.address) // user - royalty recipient
                await royaltyNft
                    .connect(user)
                    .transferFrom(user.address, deployer.address, 0)
                await royaltyNft.approve(erc721market.address, 0)
                await erc721market.listERC721Item(
                    royaltyNft.address,
                    0,
                    toWei(777)
                ) // deployer - seller
            })

            it("sets royalty fee to the recipient", async function () {
                await erc721market
                    .connect(buyer)
                    .buyERC721Item(royaltyNft.address, 0, { value: toWei(777) })

                // user - royalty recipient
                const recipientProceeds = await market.profitOf(user.address)
                // deployer - seller
                const sellerProceeds = await market.profitOf(deployer.address)
                const royaltyAmount = toWei(777).mul(100).div(10000) // 1%

                expect(recipientProceeds).to.eq(royaltyAmount)
                expect(sellerProceeds).to.eq(toWei(777).sub(royaltyAmount))
            })
        })

        describe("Selling non Royalty nfts", function () {
            beforeEach(async function () {
                simpleNFT = await ethers.getContract("SimpleNFT")

                await simpleNFT.mint(user.address) // user - royalty recipient

                await simpleNFT.connect(user).approve(erc721market.address, 0)
                await erc721market
                    .connect(user)
                    .listERC721Item(simpleNFT.address, 0, toWei(123))
            })

            it("seller gets full value", async function () {
                await erc721market
                    .connect(buyer)
                    .buyERC721Item(simpleNFT.address, 0, { value: toWei(123) })

                const sellerProceeds = await market.profitOf(user.address)

                expect(sellerProceeds).to.eq(toWei(123))
            })
        })
    })
}
