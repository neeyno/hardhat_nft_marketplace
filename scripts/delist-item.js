const { getNamedAccounts, ethers, network } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

async function main() {
    const deployer = (await getNamedAccounts()).deployer
    const nftSample = await ethers.getContract("BasicNFT", deployer)
    const nftMarketplace = await ethers.getContract("NFTMarketplace", deployer)
    //
    console.log("Delisting...")
    const tokenIdlatest = await nftSample.getTokenCounter()
    const delistTx = await nftMarketplace.cancelListing(
        nftSample.address,
        tokenIdlatest
    )
    const delistTxReceipt = await delistTx.wait(1)
    const { nftAddress, tokenId } = delistTxReceipt.events[0].args
    console.log(`NFT tokenId: ${tokenId} \nNFT address: ${nftAddress}`)
    //

    if (network.config.chainId == 31337) {
        await moveBlocks(2, 1000)
    }
    console.log("------------------------------------------")
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
