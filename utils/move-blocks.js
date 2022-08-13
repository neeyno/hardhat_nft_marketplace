const { network, ethers } = require("hardhat")

function sleep(timeInMs) {
    return new Promise((resolve) => setTimeout(resolve, timeInMs))
}

async function moveBlocks(amount, sleepAmount = 0) {
    console.log("Moving blocks...")
    for (let index = 0; index < amount; index++) {
        await network.provider.request({
            method: "evm_mine",
            params: [],
        })

        if (sleepAmount > 0) {
            console.log(`sleeping ${index + 1} sec`)
            await sleep(sleepAmount)
        }
    }
}

module.exports = {
    moveBlocks,
    sleep,
}
