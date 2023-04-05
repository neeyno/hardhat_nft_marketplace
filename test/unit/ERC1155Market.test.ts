import { expect } from "chai"
import { ethers, deployments, network } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { BigNumber } from "ethers"
import {
    NFTMarketBase,
    ERC1155Marketplace,
    SimpleNFT1155,
    RoyaltiNFT1155,
    SimpleNFT__factory,
} from "../../typechain-types"

const toWei = (value: number) => ethers.utils.parseEther(value.toString()) // toWei(1) = 10e18 wei
const fromWei = (value: BigNumber) => ethers.utils.formatEther(value) // fromWei(10e18) = "1" eth

if (!developmentChains.includes(network.name)) {
    console.log("skip unit test")
    describe.skip
} else {
    describe("ERC1155 Marketplace unit test", function () {
        let [deployer, user, buyer]: SignerWithAddress[] = []
        let erc1155market: ERC1155Marketplace
        let royaltyNft: RoyaltiNFT1155
        let simpleNFT: SimpleNFT1155
        let market: NFTMarketBase

        before(async function () {
            const accounts = await ethers.getSigners()
            ;[deployer, user, buyer] = accounts
        })

        beforeEach(async function () {
            await deployments.fixture(["diamond", "base", "erc1155"])
            const diamond = await ethers.getContract("NFTMarketDiamond")

            market = await ethers.getContractAt(
                "NFTMarketBase",
                diamond.address
            )

            erc1155market = await ethers.getContractAt(
                "ERC1155Marketplace",
                diamond.address
            )

            // royaltyNft = await ethers.getContract("RoyaltiNFT1155")
            simpleNFT = await ethers.getContract("SimpleNFT1155")
        })

        describe("Item listng - listERC1155Item()", function () {
            beforeEach(async function () {
                // mints nft with tokenId: 0 and amount: 10
                await simpleNFT.mint(deployer.address, 0, 10, "0x")

                // approve nft for the marketplace
                await simpleNFT.setApprovalForAll(market.address, true)
            })

            it("reverts if the price parameter is 0", async function () {
                await expect(
                    erc1155market.listERC1155Item(
                        simpleNFT.address,
                        0,
                        10,
                        toWei(0)
                    )
                ).to.be.revertedWithCustomError(
                    erc1155market,
                    "NFTMarket__ZeroValue"
                )
            })

            it("reverts if the quantity parameter is 0", async function () {
                await expect(
                    erc1155market.listERC1155Item(
                        simpleNFT.address,
                        0,
                        0, // 0 quantity
                        toWei(1)
                    )
                ).to.be.revertedWithCustomError(
                    erc1155market,
                    "NFTMarket__ZeroValue"
                )
            })

            it("reverts if item is not approved", async function () {
                await simpleNFT.mint(user.address, 0, 1, "0x")

                await expect(
                    erc1155market
                        .connect(user)
                        .listERC1155Item(simpleNFT.address, 0, 1, toWei(1))
                ).to.be.revertedWithCustomError(
                    erc1155market,
                    "NFTMarket__NotApproved"
                )
            })

            it("checks seller balance and ownership", async function () {
                await expect(
                    erc1155market.listERC1155Item(
                        simpleNFT.address,
                        0,
                        11,
                        toWei(1)
                    )
                ).to.be.revertedWithCustomError(
                    erc1155market,
                    "NFTMarket__InsufficientBalance"
                )
            })

            it("rewtite existing listing", async function () {
                await erc1155market.listERC1155Item(
                    simpleNFT.address,
                    0,
                    1,
                    toWei(1)
                )
            })
            it("allows to revoke some quantity ", async function () {})

            /* it("checks the owner of the item", async function () {
            // try to list tokenId 1 from user acc
            await expect(
                erc1155market
                    .connect(user)
                    .listERC1155Item(simpleNFT.address, 0, toWei(1))
            ).to.be.revertedWithCustomError(
                erc1155market,
                "NFTMarket__NotOwner"
            )
        }) */

            it("sets a new item to the marketplace listing", async function () {
                await erc1155market.listERC1155Item(
                    simpleNFT.address,
                    0,
                    10,
                    toWei(1)
                )
                const { seller, price, quantity } =
                    await market.getERC1155Listing(simpleNFT.address, 0)

                expect(seller).to.equal(deployer.address)
                expect(price).to.equal(toWei(1))
                expect(quantity).to.equal(10)
            })

            it("emits event - ERC1155ItemListed", async function () {
                await expect(
                    erc1155market.listERC1155Item(
                        simpleNFT.address,
                        0,
                        10,
                        toWei(0.99)
                    )
                )
                    .to.emit(erc1155market, "ERC1155ItemListed")
                    .withArgs(
                        deployer.address,
                        simpleNFT.address,
                        0,
                        10,
                        toWei(0.99)
                    )
            })
        })

        describe("Canceling listing - cancelERC1155Listing()", function () {
            beforeEach(async function () {
                // mints nft with tokenId: 0 and amount: 10
                await simpleNFT.mint(deployer.address, 0, 10, "0x")

                // approve nft for the marketplace
                await simpleNFT.setApprovalForAll(market.address, true)

                // list item to the marketplace
                await erc1155market.listERC1155Item(
                    simpleNFT.address,
                    0,
                    10,
                    toWei(2)
                )
            })

            it("only owner able to cancel the listing", async function () {
                await expect(
                    erc1155market
                        .connect(user)
                        .cancelERC1155Listing(simpleNFT.address, 0)
                ).to.be.revertedWithCustomError(
                    erc1155market,
                    "NFTMarket__NotOwner"
                )
            })

            /* it("checks that item is listed on the marketplace", async function () {
            await simpleNFT.mint(deployer.address, 1, 10, "0x") // tokenId 1

            await expect(
                erc1155market.cancelERC1155Listing(simpleNFT.address, 1)
            ).to.be.revertedWithCustomError(
                erc1155market,
                "NFTMarket__ItemNotListed"
            )
        }) */

            it("removes item from the listing", async function () {
                await erc1155market.cancelERC1155Listing(simpleNFT.address, 0)
                const { price, seller, quantity } =
                    await market.getERC1155Listing(simpleNFT.address, 0)

                expect(price).to.equals(0)
                expect(seller).to.equals(ethers.constants.AddressZero)
                expect(quantity).to.equals(0)
            })

            it("emits event - ERC1155ItemDelisted", async function () {
                await expect(
                    erc1155market.cancelERC1155Listing(simpleNFT.address, 0)
                )
                    .to.emit(erc1155market, "ERC1155ItemDelisted")
                    .withArgs(deployer.address, simpleNFT.address, 0)
            })
        })

        describe("Update listing price - updateERC1155Price()", function () {
            beforeEach(async function () {
                // mints nft with tokenId: 0 and amount: 10
                await simpleNFT.mint(deployer.address, 0, 10, "0x")

                // approve nft for the marketplace
                await simpleNFT.setApprovalForAll(market.address, true)

                // list item to the marketplace
                await erc1155market.listERC1155Item(
                    simpleNFT.address,
                    0,
                    10,
                    toWei(3)
                )
            })

            it("only owner able to update the listing", async function () {
                await expect(
                    erc1155market
                        .connect(user)
                        .updateERC1155Price(simpleNFT.address, 0, toWei(4))
                ).to.be.revertedWithCustomError(
                    erc1155market,
                    "NFTMarket__NotOwner"
                )
            })

            it("updates listing price with new value", async function () {
                const {
                    price: priceBefore,
                    seller: sellerBefore,
                    quantity: QuantityBefore,
                } = await market.getERC1155Listing(simpleNFT.address, 0)

                await erc1155market.updateERC1155Price(
                    simpleNFT.address,
                    0,
                    toWei(4)
                )

                const {
                    price: newPrice,
                    seller,
                    quantity,
                } = await market.getERC1155Listing(simpleNFT.address, 0)

                expect(priceBefore).to.eq(toWei(3))
                expect(newPrice).to.eq(toWei(4))
                expect(seller).to.eq(sellerBefore)
                expect(quantity).to.eq(QuantityBefore)
            })

            it("emits event on price update - ERC1155ItemUpdated", async function () {
                await expect(
                    erc1155market.updateERC1155Price(
                        simpleNFT.address,
                        0,
                        toWei(4)
                    )
                )
                    .to.emit(erc1155market, "ERC1155ItemUpdated")
                    .withArgs(deployer.address, simpleNFT.address, 0, toWei(4))
            })
        })

        describe("Buying item - buyERC1155Item()", function () {
            beforeEach(async function () {
                // mints nft with tokenId: 0 and amount: 10
                await simpleNFT.mint(deployer.address, 0, 2, "0x")

                // approve nft for the marketplace
                await simpleNFT.setApprovalForAll(market.address, true)

                // list item to the marketplace
                await erc1155market.listERC1155Item(
                    simpleNFT.address,
                    0,
                    2,
                    toWei(5)
                )
            })

            it("checks that item is listed on the marketplace", async function () {
                await expect(
                    erc1155market.buyERC1155Item(simpleNFT.address, 2, 1, {
                        value: toWei(0.1),
                    })
                ).to.be.revertedWithCustomError(
                    erc1155market,
                    "NFTMarket__ItemNotListed"
                )
            })

            it("checks price matching", async function () {
                await expect(
                    erc1155market
                        .connect(buyer)
                        .buyERC1155Item(simpleNFT.address, 0, 2, {
                            value: toWei(9.99),
                        })
                )
                    .to.be.revertedWithCustomError(
                        erc1155market,
                        "NFTMarket__PriceNotMet"
                    )
                    .withArgs(toWei(9.99), toWei(10))
            })

            it("removes bought item from the listing", async function () {
                await erc1155market
                    .connect(buyer)
                    .buyERC1155Item(simpleNFT.address, 0, 2, {
                        value: toWei(10),
                    })

                const { price, seller, quantity } =
                    await market.getERC1155Listing(simpleNFT.address, 0)

                expect(price).to.eq(0)
                expect(seller).to.eq(ethers.constants.AddressZero)
                expect(quantity).to.eq(0)
            })

            it("sets new proceeds to seller balance", async function () {
                const proceedsBefore = await market.profitOf(deployer.address)

                await erc1155market
                    .connect(buyer)
                    .buyERC1155Item(simpleNFT.address, 0, 2, {
                        value: toWei(10),
                    })

                const proceedsAfter = await market.profitOf(deployer.address)

                expect(proceedsBefore).to.eq(0)
                expect(proceedsAfter).to.eq(toWei(10))
            })

            it("transfers item to the buyer", async function () {
                const buyerBalanceBefore = await simpleNFT.balanceOf(
                    buyer.address,
                    0
                )

                await erc1155market
                    .connect(buyer)
                    .buyERC1155Item(simpleNFT.address, 0, 2, {
                        value: toWei(10),
                    })
                const buyerBalanceAfter = await simpleNFT.balanceOf(
                    buyer.address,
                    0
                )

                expect(buyerBalanceBefore).to.eq(0)
                expect(buyerBalanceAfter).to.eq(2)
            })

            it("emits event - ERC1155ItemBought", async function () {
                await expect(
                    erc1155market
                        .connect(buyer)
                        .buyERC1155Item(simpleNFT.address, 0, 2, {
                            value: toWei(10),
                        })
                )
                    .to.emit(erc1155market, "ERC1155ItemBought")
                    .withArgs(
                        deployer.address,
                        buyer.address,
                        simpleNFT.address,
                        0,
                        2,
                        toWei(10),
                        "0x"
                    )
            })

            it("reverts if seller revokes approval", async function () {
                await simpleNFT.setApprovalForAll(market.address, false)

                let iface = new ethers.utils.Interface([
                    "function Error(string)",
                ])
                // Error(string) Solidity has another built-in error Panic(uint)
                // const errorSelector = descr.getSighash("Error(string)")

                const errorMsg = iface.encodeFunctionData("Error(string)", [
                    "ERC1155: caller is not token owner or approved",
                ])

                await expect(
                    erc1155market
                        .connect(buyer)
                        .buyERC1155Item(simpleNFT.address, 0, 2, {
                            value: toWei(10),
                        })
                )
                    .to.be.revertedWithCustomError(
                        erc1155market,
                        "NFTMarket__NFTTransferFailed"
                    )
                    .withArgs(errorMsg)
            })
        })

        /* 
    describe("tx fails if seller removes approval  - buyERC721Item()", function () {
        beforeEach(async function () {
            await simpleNFT.mint(deployer.address)
            await simpleNFT.approve(erc1155market.address, 0)
            await erc1155market.listERC1155Item(simpleNFT.address, 0, toWei(6))
        })

        it("reverts with custom error - NotApproved", async function () {
            await simpleNFT.approve(ethers.constants.AddressZero, 0)

            await expect(
                erc1155market
                    .connect(user)
                    .buyERC721Item(simpleNFT.address, 0, {
                        value: toWei(6),
                    })
            ).to.be.revertedWithCustomError(
                erc1155market,
                "NFTMarket__NotApprovedForMarketplace"
            )
        })
        
        let tx: unknown

        it("restores user balance", async function () {
            await simpleNFT.approve(ethers.constants.AddressZero, 0)
            console.log(
                (await ethers.provider.getBalance(user.address)).toString()
            )
            try {
                tx = await erc1155market
                    .connect(user)
                    .buyERC721Item(simpleNFT.address, 0, {
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
        }) 
        
    })
    */

        /* 
    describe("Selling Royalty NFT", function () {
        beforeEach(async function () {
            await simpleNFT.mint(user.address) // user - royalty recipient
            await royaltyNft
                .connect(user)
                .transferFrom(user.address, deployer.address, 0)
            await simpleNFT.approve(erc1155market.address, 0)
            await erc1155market.listERC1155Item(
                simpleNFT.address,
                0,
                toWei(777)
            ) // deployer - seller
        })

        it("sets royalty fee to the recipient", async function () {
            await erc1155market
                .connect(buyer)
                .buyERC721Item(simpleNFT.address, 0, { value: toWei(777) })

            // user - royalty recipient
            const recipientProceeds = await market.getProfits(user.address)
            // deployer - seller
            const sellerProceeds = await market.getProfits(deployer.address)
            const royaltyAmount = toWei(777).mul(100).div(10000) // 1%

            expect(recipientProceeds).to.eq(royaltyAmount)
            expect(sellerProceeds).to.eq(toWei(777).sub(royaltyAmount))
        })
    })

    describe("Selling non Royalty nfts", function () {
        let simpleNFT: SimpleNFT1155
        beforeEach(async function () {
            await deployments.fixture("SimpleNFT")
            simpleNFT = await ethers.getContract("SimpleNFT")

            await simpleNFT.mint(user.address) // user - royalty recipient

            await simpleNFT.connect(user).approve(erc1155market.address, 0)
            await erc1155market
                .connect(user)
                .listERC1155Item(simpleNFT.address, 0, toWei(123))
        })

        it("seller gets full value", async function () {
            await erc1155market
                .connect(buyer)
                .buyERC721Item(simpleNFT.address, 0, { value: toWei(123) })

            const sellerProceeds = await market.getProfits(user.address)

            expect(sellerProceeds).to.eq(toWei(123))
        })
    }) 
    */
    })
}
