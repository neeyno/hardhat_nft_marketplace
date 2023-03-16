import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import { getNamedAccounts, deployments } from "hardhat"

const deploySimpleNFT: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const nftMarket = await deploy("SimpleNFT", {
        contract: "SimpleNFT",
        from: deployer,
        log: true,
        args: [],
    })

    log(`----------------------------------------------------`)
}

export default deploySimpleNFT
deploySimpleNFT.tags = [`all`, `SimpleNFT`, `erc721`]
