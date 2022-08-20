const { network, ethers } = require("hardhat")
const fs = require("fs")

const FRONTEND_ADDRESSES_FILE =
    "../nextjs_nft_marketplace/constants/contractAddresses.json"
const FRONTEND_ABI_LOCATION = "../nextjs_nft_marketplace/constants/"

async function updateContractAddresses() {
    const nftMarketplace = await ethers.getContract("NFTMarketplace")
    const contractAddresses = JSON.parse(
        fs.readFileSync(FRONTEND_ADDRESSES_FILE, "utf8")
    )
    const chainId = network.config.chainId.toString()

    if (chainId in contractAddresses) {
        if (
            !contractAddresses[chainId]["NFTMarketplace"].includes(
                nftMarketplace.address
            )
        ) {
            contractAddresses[chainId]["NFTMarketplace"].push(
                nftMarketplace.address
            )
        }
    } else {
        contractAddresses[chainId] = {
            NFTMarketplace: [nftMarketplace.address],
        }
    }
    //contractAddresses[chainId] = [nftMarketplace.address]
    fs.writeFileSync(FRONTEND_ADDRESSES_FILE, JSON.stringify(contractAddresses))
}

async function updateAbi() {
    const nftMarketplace = await ethers.getContract("NFTMarketplace")
    fs.writeFileSync(
        `${FRONTEND_ABI_LOCATION}NFTMarketplace.json`,
        nftMarketplace.interface.format(ethers.utils.FormatTypes.json)
    )

    const nftSample = await ethers.getContract("BasicNFT")
    fs.writeFileSync(
        `${FRONTEND_ABI_LOCATION}BasicNFT.json`,
        nftSample.interface.format(ethers.utils.FormatTypes.json)
    )
}

module.exports = async function () {
    if (process.env.UPDATE_FRONTEND) {
        console.log("Updating frontend")
        await updateContractAddresses()
        await updateAbi()
        console.log("------------------------------------------")
    }
}

module.exports.tags = ["all", "frontend"]
