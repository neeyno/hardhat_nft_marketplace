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
    describe("Marketplace Base unit test", function () {
        let [deployer, user, buyer]: SignerWithAddress[] = []
        let erc721market: ERC721Marketplace
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

            simpleNFT = await ethers.getContract("SimpleNFT")
        })

        describe("seller is able to withdraw profits", function () {
            beforeEach(async function () {
                await simpleNFT.mint(deployer.address) // mints nft with tokenId: 0
                await simpleNFT.approve(erc721market.address, 0)
                await erc721market.listERC721Item(
                    simpleNFT.address,
                    0,
                    toWei(1)
                )
                await erc721market
                    .connect(buyer)
                    .buyERC721Item(simpleNFT.address, 0, { value: toWei(1) })
            })

            it("withdraws seller's profits", async function () {
                const sellerBalanceBefore = await ethers.provider.getBalance(
                    deployer.address
                )

                const tx = await market.withdrawProfits(deployer.address)
                const txReceipt = await tx.wait()
                const { effectiveGasPrice, gasUsed } = txReceipt

                const sellerBalanceAfter = await ethers.provider.getBalance(
                    deployer.address
                )

                const estimatedBalance = sellerBalanceBefore
                    .sub(effectiveGasPrice.mul(gasUsed))
                    .add(toWei(1))

                expect(sellerBalanceAfter).to.eq(estimatedBalance)
            })

            it("emits event - MarketWithdrawal", async function () {
                await expect(market.withdrawProfits(deployer.address))
                    .to.emit(market, "MarketWithdrawal")
                    .withArgs(toWei(1), "0x")
            })
        })
    })
}
