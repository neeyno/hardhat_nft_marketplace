import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import { getNamedAccounts, deployments, network } from "hardhat"
import { developmentChains, confirmationsNum } from "../helper-hardhat-config"
import verify from "../utils/verify"

const deployERC1155Marketplace: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deploy, log, getArtifact } = deployments
    const { deployer } = await getNamedAccounts()

    const contractName = "ERC1155Marketplace"
    const contractArgs: any[] = []

    const deployedContract = await deploy(contractName, {
        contract: contractName,
        from: deployer,
        log: true,
        args: contractArgs,
        waitConfirmations: confirmationsNum(network.name),
    })

    if (!developmentChains.includes(network.name)) {
        await verify(
            deployedContract.address,
            contractArgs,
            await getArtifact(contractName)
        )
    }

    log(`----------------------------------------------------`)
}

export default deployERC1155Marketplace
deployERC1155Marketplace.tags = [`all`, `ERC1155Marketplace`, `erc1155`]
