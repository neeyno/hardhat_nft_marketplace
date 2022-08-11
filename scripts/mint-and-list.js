const { getNamedAccounts, ethers } = require("hardhat")

async function main() {
    const deployer = (await getNamedAccounts()).deployer
    const nftSample = await ethers.getContract("BasicNFT", deployer)
    const nftMarketplace = await ethers.getContract("NFTMarketplace", deployer)
    //
    console.log("Minting...")
    const mintTx = await nftSample.mintNFT()
    const mintTxReceipt = await mintTx.wait(1)
    const tokenId = mintTxReceipt.events[0].args.tokenId
    console.log(`NFT tokenId: ${tokenId} \nNFT tokenURI: ${await nftSample.tokenURI(0)}`)
    //
    console.log("Listing...")
    await nftSample.approve(nftMarketplace.address, tokenId)
    const priceValue = ethers.utils.parseEther("0.1")
    const listTx = await nftMarketplace.listItem(nftSample.address, tokenId, priceValue)
    const listTxReceipt = await listTx.wait(1)
    const { seller, price } = listTxReceipt.events[0].args
    //await nftMarketplace.getListing(nftSample.address, tokenId)
    console.log(`Price: ${ethers.utils.formatUnits(price, 18)} Eth\nSeller: ${seller}`)

    console.log("------------------------------------------")
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
