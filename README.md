<div align="center">
 <h2 align="center">NFT Marketplace</h2>
</div>
<hr>

This NFT marketplace is designed with flexibility and longevity in mind. It can seamlessly integrate various types of NFTs and automatically calculate royalties, and it's built on an upgradable smart contract that implements the diamond ERC standard. This means that the smart contract can be maintained and updated with new features without the need to touch storage. Plus, the contract can easily accommodate additional storage and logic, making it an ideal solution for future-proof NFT projects.

## Requirements

npm 7 or later
```console
npm --version
```
typescript
```console
tsc --version
```

## Installation

1. Clone repo: 

```bash
mkdir nft-marketplace

git clone https://github.com/neeyno/hardhat_nft_marketplace.git nft-marketplace
```

2. Install NPM packages:

```bash 
cd nft-marketplace

npm install
```

### Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
