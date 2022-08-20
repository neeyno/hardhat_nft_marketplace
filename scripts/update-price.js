const { getNamedAccounts, ethers, network } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

async function main() {
    const deployer = (await getNamedAccounts()).deployer
    const nftSample = await ethers.getContract("BasicNFT", deployer)
    const nftMarketplace = await ethers.getContract("NFTMarketplace", deployer)
    //
    console.log("Updating...")
    const newValue = ethers.utils.parseEther("1")
    const tokenIdlatest = await nftSample.getTokenCounter()
    const updateTx = await nftMarketplace.updatePrice(
        nftSample.address,
        tokenIdlatest,
        newValue
    )
    const updateTxReceipt = await updateTx.wait(1)
    const { seller, price } = updateTxReceipt.events[0].args
    console.log(`New price: ${ethers.utils.formatUnits(price, 18)} Eth`)
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
