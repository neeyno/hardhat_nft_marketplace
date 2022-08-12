const { assert, expect } = require("chai")
const { ethers, deployments, getNamedAccounts, network } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("NFT Marketplace unit test", async function () {
          let nftMarketplace, nftSample, nftAddress, deployer, accounts
          //const chainId = network.config.chainId
          const tokenId = "1"
          const price1Eth = ethers.utils.parseEther("1")
          //const accounts = await ethers.getSigners()

          beforeEach(async function () {
              deployer = (await getNamedAccounts()).deployer
              await deployments.fixture(["test", "market1"])
              nftSample = await ethers.getContract("BasicNFT", deployer)
              nftAddress = nftSample.address
              nftMarketplace = await ethers.getContract("NFTMarketplace", deployer)
              accounts = await ethers.getSigners()
          })

          //   describe("Contructor", function () {
          //       it("", async function () {
          //       })
          //   })

          describe("Item listng", function () {
              beforeEach(async function () {
                  await nftSample.mintNFT()
              })

              it("reverts if not approved", async function () {
                  await expect(
                      nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
                  ).to.be.revertedWith("NFTMarketplace__NotApprovedForMarketplace()")
              })

              it("checks that item has not been listed", async function () {
                  await nftSample.approve(nftMarketplace.address, tokenId)
                  await nftMarketplace.listItem(nftAddress, tokenId, price1Eth)

                  await expect(
                      nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
                  ).to.be.revertedWith("NFTMarketplace__ItemAlreadyListed")
              })

              it("checks the owner of the item", async function () {
                  await nftSample.approve(nftMarketplace.address, tokenId)
                  await expect(
                      nftMarketplace.connect(accounts[1]).listItem(nftAddress, tokenId, price1Eth)
                  ).to.be.revertedWith("NFTMarketplace__NotOwner")
              })

              it("reverts if the price is less or equal 0", async function () {
                  await nftSample.approve(nftMarketplace.address, tokenId)
                  const zeroPrice = ethers.utils.parseEther("0")
                  await expect(
                      nftMarketplace.listItem(nftAddress, tokenId, zeroPrice)
                  ).to.be.revertedWith("NFTMarketplace__PriceMustBeAboveZero()")
              })

              it("lists the item to the marketplace", async function () {
                  await nftSample.approve(nftMarketplace.address, tokenId)
                  await nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
                  const { price, seller } = await nftMarketplace.getListing(nftAddress, tokenId)

                  assert.equal(price.toString(), price1Eth.toString())
                  assert.equal(seller, deployer)
              })

              it("emits event(ItemListed)", async function () {
                  await nftSample.approve(nftMarketplace.address, tokenId)
                  await expect(nftMarketplace.listItem(nftAddress, tokenId, price1Eth))
                      .to.emit(nftMarketplace, "ItemListed")
                      .withArgs(deployer, nftAddress, tokenId, price1Eth)
              })
          })

          describe("Buying item", function () {
              beforeEach(async function () {
                  await nftSample.mintNFT()
                  await nftSample.approve(nftMarketplace.address, tokenId)
                  await nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
              })

              it("checks that the item is listed", async function () {
                  await expect(nftMarketplace.buyItem(nftAddress, "2")).to.be.revertedWith(
                      "NFTMarketplace__ItemNotListed"
                  )
              })

              it("checks price matching", async function () {
                  const sendValue = ethers.utils.parseEther("0.99")
                  await expect(
                      nftMarketplace.buyItem(nftAddress, tokenId, { value: sendValue })
                  ).to.be.revertedWith("NFTMarketplace__PriceNotMet")
              })

              it("adds seller's proceeds", async function () {
                  const proceedsBefore = await nftMarketplace.getProceeds(deployer)
                  const tx = await nftMarketplace
                      .connect(accounts[1])
                      .buyItem(nftAddress, tokenId, {
                          value: price1Eth,
                      })
                  await tx.wait(1)
                  const proceedsAfter = await nftMarketplace.getProceeds(deployer)

                  assert.equal("0", proceedsBefore.toString())
                  assert.equal(price1Eth.toString(), proceedsAfter.toString())
              })

              it("removes bought item", async function () {
                  const tx = await nftMarketplace
                      .connect(accounts[1])
                      .buyItem(nftAddress, tokenId, {
                          value: price1Eth,
                      })
                  await tx.wait(1)
                  const { price, seller } = await nftMarketplace.getListing(nftAddress, tokenId)

                  assert.equal("0", price.toString())
                  assert.equal("0x0000000000000000000000000000000000000000", seller.toString())
              })

              it("transfers item to the buyer", async function () {
                  const tx = await nftMarketplace
                      .connect(accounts[1])
                      .buyItem(nftAddress, tokenId, {
                          value: price1Eth,
                      })
                  await tx.wait(1)
                  const newOwner = await nftSample.ownerOf(tokenId)

                  assert.equal(accounts[1].address, newOwner)
              })

              it("emits event(ItemBought)", async function () {
                  await expect(
                      nftMarketplace.connect(accounts[1]).buyItem(nftAddress, tokenId, {
                          value: price1Eth,
                      })
                  )
                      .to.emit(nftMarketplace, "ItemBought")
                      .withArgs(accounts[1].address, nftAddress, tokenId, price1Eth)
              })
          })

          describe("Canceling listing", function () {
              beforeEach(async function () {
                  //accounts = await ethers.getSigners()
                  await nftSample.mintNFT()
                  await nftSample.approve(nftMarketplace.address, tokenId)
                  await nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
              })

              it("checks the owner of deleting item", async function () {
                  await expect(
                      nftMarketplace.connect(accounts[1]).cancelListing(nftAddress, tokenId)
                  ).to.be.revertedWith("NFTMarketplace__NotOwner()")
              })

              it("checks that item is listed", async function () {
                  await nftSample.mintNFT()
                  const tokenIdSecond = "2"
                  await expect(
                      nftMarketplace.cancelListing(nftAddress, tokenIdSecond)
                  ).to.be.revertedWith("NFTMarketplace__ItemNotListed")
              })

              it("removes chosen item", async function () {
                  const tx = await nftMarketplace.cancelListing(nftAddress, tokenId)
                  await tx.wait(1)
                  const { price, seller } = await nftMarketplace.getListing(nftAddress, tokenId)

                  assert.equal("0", price.toString())
                  assert.equal("0x0000000000000000000000000000000000000000", seller.toString())
              })

              it("emits event(ItemDelisted)", async function () {
                  await expect(nftMarketplace.cancelListing(nftAddress, tokenId))
                      .to.emit(nftMarketplace, "ItemDelisted")
                      .withArgs(deployer, nftAddress, tokenId)
              })
          })

          describe("Updating the price", function () {
              beforeEach(async function () {
                  await nftSample.mintNFT()
                  await nftSample.approve(nftMarketplace.address, tokenId)
                  await nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
              })

              it("updates the price with a new value", async function () {
                  const newValue = ethers.utils.parseEther("2")
                  const tx = await nftMarketplace.updatePrice(nftAddress, tokenId, newValue)
                  await tx.wait(1)
                  const { price, seller } = await nftMarketplace.getListing(nftAddress, tokenId)

                  assert.equal(newValue.toString(), price.toString())
                  assert.equal(deployer, seller)
              })

              it("emits event(ItemListed) on update", async function () {
                  const newValue = ethers.utils.parseEther("2")
                  await expect(nftMarketplace.updatePrice(nftAddress, tokenId, newValue))
                      .to.emit(nftMarketplace, "ItemListed")
                      .withArgs(deployer, nftAddress, tokenId, newValue)
              })
          })

          describe("Withdrawals ", function () {
              beforeEach(async function () {
                  await nftSample.mintNFT()
                  await nftSample.approve(nftMarketplace.address, tokenId)
                  await nftMarketplace.listItem(nftAddress, tokenId, price1Eth)
              })

              it("reverts if there is no proceeds", async function () {
                  await expect(
                      nftMarketplace.connect(accounts[1]).withdrawProceeds()
                  ).to.be.revertedWith("NFTMarketplace__NoProceeds()")
              })

              it("resets proceeds balance to 0", async function () {
                  const tx1 = await nftMarketplace
                      .connect(accounts[1])
                      .buyItem(nftAddress, tokenId, {
                          value: price1Eth,
                      })
                  const proceedsBefore = await nftMarketplace.getProceeds(deployer)
                  const tx2 = await nftMarketplace.withdrawProceeds()
                  const proceedsAfter = await nftMarketplace.getProceeds(deployer)

                  assert.equal(price1Eth.toString(), proceedsBefore.toString())
                  assert.equal("0", proceedsAfter.toString())
              })

              it("transfers proceeds to the seller", async function () {
                  // arrange
                  const buyTx = await nftMarketplace
                      .connect(accounts[1])
                      .buyItem(nftAddress, tokenId, {
                          value: price1Eth,
                      })
                  await buyTx.wait(1)
                  const beforeSellerBalance = await nftMarketplace.provider.getBalance(deployer)
                  // act
                  const tx = await nftMarketplace.withdrawProceeds()
                  const txReceipt = await tx.wait(1)
                  const { gasUsed, effectiveGasPrice } = txReceipt
                  const gasCost = gasUsed.mul(effectiveGasPrice) // multiply
                  const afterSelLerBalance = await nftMarketplace.provider.getBalance(deployer)
                  // assert
                  assert.equal(
                      price1Eth.add(beforeSellerBalance).toString(),
                      afterSelLerBalance.add(gasCost).toString()
                  )
              })
          })
      })
