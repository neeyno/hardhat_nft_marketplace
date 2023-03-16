import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import { getNamedAccounts, deployments } from "hardhat"

const deployRoyaltiNFT1155: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const nftMarket = await deploy("RoyaltiNFT1155", {
        contract: "RoyaltiNFT1155",
        from: deployer,
        log: true,
        args: [],
    })

    log(`----------------------------------------------------`)
}

export default deployRoyaltiNFT1155
deployRoyaltiNFT1155.tags = [`all`, `RoyaltiNFT1155`, `erc1155`]
