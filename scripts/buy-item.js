const { getNamedAccounts, ethers, network } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

async function buyItem() {
    const player = (await getNamedAccounts()).player
    const nftSampleBuyer = await ethers.getContract("BasicNFT", player)
    const nftMarketplaceBuyer = await ethers.getContract(
        "NFTMarketplace",
        player
    )

    console.log("Buying...")
    const tokenIdlatest = await nftSampleBuyer.getTokenCounter()
    // const priceValue = ethers.utils.parseEther("0.1")
    const listing = await nftMarketplaceBuyer.getListing(
        nftSampleBuyer.address,
        tokenIdlatest
    )

    const buyTx = await nftMarketplaceBuyer.buyItem(
        nftSampleBuyer.address,
        tokenIdlatest,
        {
            value: listing.price,
        }
    )
    const buyTxReceipt = await buyTx.wait(1)
    const { buyer, nftAddress, tokenId, price } = buyTxReceipt.events[2].args
    console.log(`NFT tokenId: ${tokenId}, NFT address: ${nftAddress}`)
    console.log(
        `Bought by ${buyer} with price: ${ethers.utils.formatUnits(price, 18)}`
    )

    if (network.config.chainId == 31337) {
        await moveBlocks(2, 1000)
    }
    console.log("------------------------------------------")
}

buyItem()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
