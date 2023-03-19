import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import { getNamedAccounts, deployments, network, ethers } from "hardhat"
import { developmentChains, confirmationsNum } from "../helper-hardhat-config"
import verify from "../utils/verify"

const deployDiamond: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deploy, log, getArtifact } = deployments
    const { deployer } = await getNamedAccounts()

    const diamond = await deploy("NFTMarketDiamond", {
        contract: "NFTMarketDiamond",
        from: deployer,
        log: true,
        args: [],
        waitConfirmations: confirmationsNum(network.name),
    })

    if (!developmentChains.includes(network.name)) {
        await verify(diamond.address, [], await getArtifact("NFTMarketDiamond"))
    }

    log(`----------------------------------------------------`)
}

export default deployDiamond
deployDiamond.tags = [`all`, `diamond`]
