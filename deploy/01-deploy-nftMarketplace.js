const { getNamedAccounts, deployments, network, ethers } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    log(`Network: ${network.name}`)

    // deploying nft marketplace contract
    const nftMarketplace = await deploy("NFTMarketplace", {
        contract: "NFTMarketplace",
        from: deployer,
        args: [], //  constructor args
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    // verify
    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        log("Verifying...")
        await verify(nftMarketplace.address, [])
    }

    log("------------------------------------------")
}

module.exports.tags = ["all", "market1"]
