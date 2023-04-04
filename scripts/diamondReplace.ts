import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { getSelectors, FacetCut, FacetCutAction } from "../utils/helper-diamond"
import { getNamedAccounts, deployments, ethers } from "hardhat"
import { Contract } from "ethers"

const contractsToReplace = ["ERC721Marketplace", "ERC1155Marketplace"]

async function main(contractNames: string[]) {
    // const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const diamond = await ethers.getContract("NFTMarketDiamond", deployer)
    const facetCuts: FacetCut[] = []

    for (const contractName of contractNames) {
        const contract = await ethers.getContract(contractName, deployer)

        const selectors = getSelectors(contract)

        const facetCut: FacetCut = {
            target: contract.address,
            action: FacetCutAction.Replace,
            selectors: selectors,
        }

        facetCuts.push(facetCut)
    }

    console.log("Facet Cut Action - Replace")

    const initTarget = ethers.constants.AddressZero // optional target of initialization delegatecall
    const initData = "0x" // optional initialization function call data

    const upgradeTx = await diamond.diamondCut(facetCuts, initTarget, initData)
    await upgradeTx.wait()

    console.log(`----------------------------------------------------`)
}

main(contractsToReplace)
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })

/* 
    async function main() {
  const signer = (await ethers.getSigners())[0];

  // Replace these with your actual Diamond contract's address and ABI
  const diamondAddress = "0x123...abc";
  const DiamondArtifact = await ethers.getContractFactory("YourDiamondContractName");
  const diamond = DiamondArtifact.attach(diamondAddress);

  // Replace these with your actual facet contract addresses
  const deployedFacets = [
    { name: "YourFacet1ContractName", address: "0x456...def" },
    { name: "YourFacet2ContractName", address: "0x789...ghi" },
  ];

  const facetCuts: FacetCut[] = [];

  for (const deployedFacet of deployedFacets) {
    // Load the facet contract
    const FacetArtifact = await ethers.getContractFactory(deployedFacet.name);
    const newFacet = FacetArtifact.attach(deployedFacet.address);

    // Get all the function signatures from the ABI
    const functionSelectors = newFacet.interface.fragments
      .filter((fragment) => fragment.type === "function")
      .map((fragment) => newFacet.interface.getSighash(fragment.format()));

    // Define the facet cut
    facetCuts.push({
      action: 1, // 0 for adding, 1 for replacing, 2 for removing
      facetAddress: newFacet.address,
      functionSelectors,
    });
  }

  // Execute the diamondCut function on your Diamond contract
  await diamond.diamondCut(facetCuts, ethers.constants.AddressZero, "0x");
  console.log("Diamond contract updated with new facet functions.");
}
    */
