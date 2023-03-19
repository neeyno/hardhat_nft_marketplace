import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import { getNamedAccounts, deployments, network } from "hardhat"
import {
    developmentChains,
    confirmationsNum,
    VERIFICATION_BLOCK_CONFIRMATIONS,
} from "../helper-hardhat-config"
import verify from "../utils/verify"

const deployERC721Marketplace: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deploy, log, getArtifact } = deployments
    const { deployer } = await getNamedAccounts()

    const erc721Market = await deploy("ERC721Marketplace", {
        contract: "ERC721Marketplace",
        from: deployer,
        log: true,
        args: [],
        waitConfirmations: confirmationsNum(network.name),
    })

    if (!developmentChains.includes(network.name)) {
        await verify(
            erc721Market.address,
            [],
            await getArtifact("ERC721Marketplace")
        )
    }

    log(`----------------------------------------------------`)
}

export default deployERC721Marketplace
deployERC721Marketplace.tags = [`all`, `ERC721Marketplace`, `erc721`]
