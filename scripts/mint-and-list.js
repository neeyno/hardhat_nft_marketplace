const { getNamedAccounts, ethers, network } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

async function main() {
    const deployer = (await getNamedAccounts()).deployer
    const nftSample = await ethers.getContract("BasicNFT", deployer)
    const nftMarketplace = await ethers.getContract("NFTMarketplace", deployer)
    //
    console.log("Minting...")
    const mintTx = await nftSample.mintNFT()
    const mintTxReceipt = await mintTx.wait(1)
    const tokenId = mintTxReceipt.events[0].args.tokenId
    console.log(`NFT tokenId: ${tokenId}, NFT address: ${nftSample.address}`)
    //
    console.log("Listing...")
    await nftSample.approve(nftMarketplace.address, tokenId)
    const priceValue = ethers.utils.parseEther("0.01")
    const listTx = await nftMarketplace.listItem(
        nftSample.address,
        tokenId,
        priceValue
    )
    const listTxReceipt = await listTx.wait(1)
    const { seller, price } = listTxReceipt.events[0].args
    //await nftMarketplace.getListing(nftSample.address, tokenId)
    console.log(
        `Price: ${ethers.utils.formatUnits(price, 18)} Eth, Seller: ${seller}`
    )

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
