import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import { getNamedAccounts, deployments } from "hardhat"

const deployNFTMarketplace: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const nftMarket = await deploy("NFTMarketplace", {
        contract: "NFTMarketplace",
        from: deployer,
        log: true,
        args: [],
    })

    log(`----------------------------------------------------`)
}

export default deployNFTMarketplace
deployNFTMarketplace.tags = [`all`, `NFTMarketplace`]
