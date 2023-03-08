import { Address } from "hardhat-deploy/types"
import { BigNumber, constants, Contract, ethers } from "ethers"

// Add: 0, Replace: 1, Remove: 2
export enum FacetCutAction {
    Add,
    Replace,
    Remove,
}

export interface FacetCut {
    target: Address
    action: FacetCutAction
    selectors: string[]
}

export function getSignatures(contract: Contract): string[] {
    return Object.keys(contract.interface.functions)
}

export function getSelectors(contract: Contract): string[] {
    const signatures = getSignatures(contract)
    console.log(signatures)

    const selectors = signatures.reduce(
        (result: string[], currentVal: string) => {
            if (currentVal !== "init(bytes)") {
                result.push(contract.interface.getSighash(currentVal))
            }
            return result
        },
        []
    )
    return selectors
}

/* 
export const getSingleSelector = function (): void {}

export const getSelectors0 = function (funcs: string[]): string[] {
    const selectors = funcs.map((val) => {
        const abiInterface = new ethers.utils.Interface([val])
        return abiInterface.getSighash(ethers.utils.Fragment.from(val))
    })
    return selectors
}
 */
