const { getNamedAccounts, ethers, network } = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const blocksAmount = 2
const sleepAmount = 1000

async function main() {
    console.log("Mining...")
    if (network.config.chainId == 31337) {
        await moveBlocks(blocksAmount, sleepAmount)
    }
    console.log("------------------------------------------")
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
