import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"

import { getNamedAccounts, deployments } from "hardhat"

const deployMyRoyaltyNFT: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const nftMarket = await deploy("MyRoyaltyNFT", {
        contract: "MyRoyaltyNFT",
        from: deployer,
        log: true,
        args: [],
    })

    log(`----------------------------------------------------`)
}

export default deployMyRoyaltyNFT
deployMyRoyaltyNFT.tags = [`all`, `MyRoyaltyNFT`, `erc721`]
