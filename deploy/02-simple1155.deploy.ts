import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import { getNamedAccounts, deployments } from "hardhat"

const deploySimpleNFT1155: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const nftMarket = await deploy("SimpleNFT1155", {
        contract: "SimpleNFT1155",
        from: deployer,
        log: true,
        args: [],
    })

    log(`----------------------------------------------------`)
}

export default deploySimpleNFT1155
deploySimpleNFT1155.tags = [`all`, `SimpleNFT1155`, `erc1155`]
