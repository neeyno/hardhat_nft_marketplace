import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { getSelectors, FacetCut, FacetCutAction } from "../utils/helper-diamond"
import { getNamedAccounts, deployments, ethers } from "hardhat"

const addERC721MarketFacet: DeployFunction = async function (
    hre: HardhatRuntimeEnvironment
) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const diamond = await ethers.getContract("NFTMarketDiamond", deployer)
    const marketBase = await ethers.getContract("NFTMarketBase", deployer)

    const selectors = getSelectors(marketBase)

    let facetCuts: FacetCut[] = [] // array of structured Diamond facet update data
    const initTarget = ethers.constants.AddressZero // optional target of initialization delegatecall
    const initData = "0x" // optional initialization function call data

    const facetCut: FacetCut = {
        target: marketBase.address,
        action: FacetCutAction.Add,
        selectors: selectors,
    }

    facetCuts.push(facetCut)

    log("Facet Cut Action - Add")

    const upgradeTx = await diamond.diamondCut(facetCuts, initTarget, initData)
    await upgradeTx.wait()

    log(`----------------------------------------------------`)
}

export default addERC721MarketFacet
addERC721MarketFacet.tags = [`all`, `base`, `facets`]
