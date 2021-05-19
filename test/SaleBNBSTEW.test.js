const { expectRevert, balance, constants } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const BigNumber = require('bignumber.js');
const STEW = artifacts.require("STEW")
const SaleBNBSTEW = artifacts.require("SaleBNBSTEW")

contract('SaleBNBSTEW is [Ownable]', (accounts) => {
    const [owner, acc1, nonContractAddress, whiteList1, whiteList2, whiteList3] = accounts
    const whitleListAddr = [whiteList1, whiteList2, whiteList3]
    const gas = 6721975
    const fixedSupply = new BigNumber(2.1e23) // 210000 STEW Coins

    const transferSTEWCoinsToSaleBNBSTEWContract = new BigNumber(1.47e23) // 147000
    const whiteList1BNB = new BigNumber(1e18) // 1 BNB
    const whiteList2BNB = new BigNumber(2e18) // 2 BNB
    const whiteList3BNB = new BigNumber(3e18) // 3 BNB

    let saleSTEWBNBConInstance;
    let stewConInstance;
    let txObject;

    describe('SaleBNBSTEW tests', () => {
        before(async () => {
            stewConInstance = await STEW.new(fixedSupply, { from: owner, gas })
        })
        context('constructor', () => {
            context('reverts', () => [
                it('when stewContract address is EOA', async () => {
                    await expectRevert(
                        SaleBNBSTEW.new(nonContractAddress, { from: owner, gas }),
                        "STEW address can't be EOA"
                    )
                })
            ])
            context('success', () => {
                const ownerBalanceAfterTransfer = new BigNumber(6.3e22) // 63000
                it('should deploy SaleBNBSTEW successfully', async () => {
                    saleSTEWBNBConInstance = await SaleBNBSTEW.new(stewConInstance.address, { from: owner, gas })
                    assert.ok("Contract deployed")
                })
                it('should transfer 147000 STEW to SaleBNBSTEW contract from owner', async () => {
                    txObject = await stewConInstance.transfer(saleSTEWBNBConInstance.address, transferSTEWCoinsToSaleBNBSTEWContract, { from: owner, gas })
                    assert.equal(txObject.receipt.status, true, "STEW transfer failed")
                })
                it('after STEW transfer owner"s balance should have 63000 STEW tokens', async () => {
                    const balance = new BigNumber(await stewConInstance.balanceOf.call(owner))
                    assert.equal(balance.toNumber(), ownerBalanceAfterTransfer.toNumber(), "Owner balance after STEW transfer do not match")
                })
                it('after STEW transfer SaleBNBSTEW contract"s balance should have 147000 STEW tokens', async () => {
                    const balance = new BigNumber(await stewConInstance.balanceOf.call(saleSTEWBNBConInstance.address))
                    assert.equal(balance.toNumber(), transferSTEWCoinsToSaleBNBSTEWContract.toNumber(), "SaleBNBSTEW contract balance after STEW transfer do not match")
                })
            })
        })
        context('checks constructor invocation is successful', () => {
            let stewContractAddress;
            it('should have stewConAddress to be previous deployed contract', async () => {
                stewContractAddress = await saleSTEWBNBConInstance.STEWContract.call()
                assert.equal(stewContractAddress, stewConInstance.address, "STEW contract addresses do not match")
            })
        })

        context('addWhitelistAddresses', () => {
            context('reverts', () => {
                it('when invoked by non-owner', async () => {
                    await expectRevert(
                        saleSTEWBNBConInstance.addWhitelistAddresses(whitleListAddr, { from: acc1, gas }),
                        "Ownable: caller is not the owner"
                    )
                })
                it('when any of whiteListAddrs is zero address', async () => {
                    whitleListAddr.push(constants.ZERO_ADDRESS) // INSERTS ZERO_ADDRESS
                    await expectRevert(
                        saleSTEWBNBConInstance.addWhitelistAddresses(whitleListAddr, { from: owner, gas }),
                        "Zero address not allowed"
                    )
                })
            })

            context('success', () => {
                it('should add whiteListAddrs successfully', async () => {
                    whitleListAddr.pop() // REMOVES ZERO_ADDRESS
                    txObject = await saleSTEWBNBConInstance.addWhitelistAddresses(whitleListAddr, { from: owner, gas })
                    assert.equal(txObject.receipt.status, true, "Add white list addresses failed")
                })
                it('should verify address is white listed', async () => {
                    const isWhiteListed = await saleSTEWBNBConInstance.isAddressWhiteListed.call(whitleListAddr[0])
                    assert.equal(isWhiteListed, true, "Address not white listed")
                })
                it('should verify addresse is NOT white listed', async () => {
                    const isWhiteListed = await saleSTEWBNBConInstance.isAddressWhiteListed.call(acc1)
                    assert.equal(isWhiteListed, false, "Address is white listed")
                })
            })

            context('buySTEWs', () => {
                context('reverts', () => {
                    it('when sale is not yet started', async () => {
                        await expectRevert(
                            saleSTEWBNBConInstance.buySTEWs({ from: whiteList1, gas, value: new BigNumber(1e18) }),
                            "Wait for the sale to start"
                        )
                    })
                    it('when sale is paused', async () => {
                        await saleSTEWBNBConInstance.pauseSale({ from: owner, gas })
                        await expectRevert(
                            saleSTEWBNBConInstance.buySTEWs({ from: whiteList1, gas, value: new BigNumber(1e18) }),
                            "Cannot buy, sale is paused"
                        )
                    })
                    it('when sale is ended', async () => {
                        await saleSTEWBNBConInstance.unPauseSale({ from: owner, gas })
                        await saleSTEWBNBConInstance.endSale({ from: owner, gas })
                        await expectRevert(
                            saleSTEWBNBConInstance.buySTEWs({ from: whiteList1, gas, value: new BigNumber(1e18) }),
                            "Sale ended"
                        )
                    })
                    context('getSTEWsForBNB', () => {
                        before(async () => {
                            stewConInstance = await STEW.new(fixedSupply, { from: owner, gas })
                            saleSTEWBNBConInstance = await SaleBNBSTEW.new(stewConInstance.address, { from: owner, gas })
                            await stewConInstance.transfer(saleSTEWBNBConInstance.address, transferSTEWCoinsToSaleBNBSTEWContract, { from: owner, gas })
                            await saleSTEWBNBConInstance.addWhitelistAddresses(whitleListAddr, { from: owner, gas })
                            await saleSTEWBNBConInstance.startSale({ from: owner, gas })
                            await saleSTEWBNBConInstance.toggleSalePreToPublic({ from: owner, gas })
                        })
                        context('reverts', () => {
                            it('when noOfBNBs < 1 BNB', async () => {
                                await expectRevert(
                                    saleSTEWBNBConInstance.buySTEWs({ from: whiteList1, gas, value: new BigNumber(0.9e18) }),
                                    "1 BNB minimum criteria fails"
                                )
                            })
                            it('when caller is not white listed in presale', async () => {
                                await expectRevert(
                                    saleSTEWBNBConInstance.buySTEWs({ from: acc1, gas, value: whiteList1BNB }),
                                    "Caller is not white listed"
                                )
                            })
                        })
                    })
                })

                context('success', () => {
                    let stewBalance;
                    it('should buy 15 STEWS for whiteList1 during presale', async () => {
                        txObject = await saleSTEWBNBConInstance.buySTEWs({ from: whiteList1, gas, value: whiteList1BNB })
                        assert.equal(txObject.receipt.status, true, "Buy STEWs failed")
                    })
                    it('should buy 30 STEWS for whiteList2 during presale', async () => {
                        txObject = await saleSTEWBNBConInstance.buySTEWs({ from: whiteList2, gas, value: whiteList2BNB })
                        assert.equal(txObject.receipt.status, true, "Buy STEWs failed")
                    })
                    it('should buy 45 STEWS for whiteList3 during presale', async () => {
                        txObject = await saleSTEWBNBConInstance.buySTEWs({ from: whiteList3, gas, value: whiteList3BNB })
                        assert.equal(txObject.receipt.status, true, "Buy STEWs failed")
                    })
                    it('should verify whiteList1 has 15 STEWS', async () => {
                        stewBalance = new BigNumber(await stewConInstance.balanceOf.call(whiteList1))
                        assert.equal(stewBalance.toNumber(), 15e18, "STEW balance do not match")
                    })
                    it('should verify whiteList2 has 30 STEWS', async () => {
                        stewBalance = new BigNumber(await stewConInstance.balanceOf.call(whiteList2))
                        assert.equal(stewBalance.toNumber(), 30e18, "STEW balance do not match")
                    })
                    it('should verify whiteList3 has 45 STEWS', async () => {
                        stewBalance = new BigNumber(await stewConInstance.balanceOf.call(whiteList3))
                        assert.equal(stewBalance.toNumber(), 45e18, "STEW balance do not match")
                    })
                    it('should verify SaleSTEWBNB has 146910 STEWS', async () => {
                        stewBalance = new BigNumber(await stewConInstance.balanceOf.call(saleSTEWBNBConInstance.address))
                        assert.equal(stewBalance.toNumber(), 1.4691e23, "STEW balance do not match")
                    })
                })
            })

            context('after presale', () => {
                const acc1BNB = new BigNumber(20e18) // 20 BNB
                before(async () => {
                    await saleSTEWBNBConInstance.toggleSalePreToPublic({ from: owner, gas })
                })
                it('should buy 240 STEWS for acc1 during presale', async () => {
                    txObject = await saleSTEWBNBConInstance.buySTEWs({ from: acc1, gas, value: acc1BNB })
                    assert.equal(txObject.receipt.status, true, "Buy STEWs failed")
                })
                it('should verify acc1 has 240 STEWS', async () => {
                    stewBalance = new BigNumber(await stewConInstance.balanceOf.call(acc1))
                    assert.equal(stewBalance.toNumber(), 240e18, "STEW balance do not match")
                })
                it('should verify SaleSTEWBNB has 146670 STEWS', async () => {
                    stewBalance = new BigNumber(await stewConInstance.balanceOf.call(saleSTEWBNBConInstance.address))
                    assert.equal(stewBalance.toNumber(), 1.4667e23, "STEW balance do not match")
                })
            })

            context('withdrawBNBs', () => {
                it('before withdraw should verify contract balance to be 26 BNB', async () => {
                    const balanceEth = await balance.current(saleSTEWBNBConInstance.address, 'ether')
                    assert.equal(balanceEth.toNumber(), 26, "Balances do not match")
                })

                it('should withdraw 26 BNBs', async () => {
                    txObject = await saleSTEWBNBConInstance.withdrawBNBs({ from: owner, gas })
                    assert.equal(txObject.receipt.status, true, "Witndraw BNB failed")
                })

                it('after withdraw should verify contract balance to be 0 BNB', async () => {
                    const balanceEth = await balance.current(saleSTEWBNBConInstance.address, 'ether')
                    assert.equal(balanceEth.toNumber(), 0, "Balances do not match")
                })
            })

            context('transferSTEWs', () => {
                it('should transfer all the STEWs back to the owner', async () => {
                    txObject = await saleSTEWBNBConInstance.transferSTEWs({ from: owner, gas })
                    assert.equal(txObject.receipt.status, true, "Transfer STEWs failed")
                })
                it('should verify SaleSTEWBNB has 0 STEWS', async () => {
                    stewBalance = new BigNumber(await stewConInstance.balanceOf.call(saleSTEWBNBConInstance.address))
                    assert.equal(stewBalance.toNumber(), 0, "STEW balance do not match")
                })
            })

            context('buySTEWs uncoverd branches', () => {
                before(async () => {
                    stewConInstance = await STEW.new(fixedSupply, { from: owner, gas })
                    saleSTEWBNBConInstance = await SaleBNBSTEW.new(stewConInstance.address, { from: owner, gas })
                    await stewConInstance.transfer(saleSTEWBNBConInstance.address, transferSTEWCoinsToSaleBNBSTEWContract, { from: owner, gas })
                    await saleSTEWBNBConInstance.addWhitelistAddresses(whitleListAddr, { from: owner, gas })
                    await saleSTEWBNBConInstance.startSale({ from: owner, gas })
                    await saleSTEWBNBConInstance.toggleSalePreToPublic({ from: owner, gas })
                })
                context('success', () => {
                    let stewBalance;
                    it('should buy 146490 STEWS for whiteList1 during presale', async () => {
                        txObject = await saleSTEWBNBConInstance.buySTEWs({ from: whiteList1, gas, value: new BigNumber(9.766e21) })
                        assert.equal(txObject.receipt.status, true, "Buy STEWs failed")
                    })
                    it('should verify whiteList1 has 147000 STEWS', async () => {
                        stewBalance = new BigNumber(await stewConInstance.balanceOf.call(whiteList1))
                        assert.equal(stewBalance.toNumber(), 1.46490e23, "STEW balance do not match")
                    })
                    it('should verify SaleSTEWBNB has 510 STEWS', async () => {
                        stewBalance = new BigNumber(await stewConInstance.balanceOf.call(saleSTEWBNBConInstance.address))
                        assert.equal(stewBalance.toNumber(), 5.1e20, "STEW balance do not match")
                    })
                    it('reverts when trying to buy more than available STEWs', async () => {
                        await expectRevert(
                            saleSTEWBNBConInstance.buySTEWs({ from: whiteList1, gas, value: new BigNumber(3.5e19) }),
                            "Buying exceeds available STEWs"
                        )
                    })
                    it('succeeds in buying the exact remaining number of STEWs', async () => {
                        txObject = await saleSTEWBNBConInstance.buySTEWs({ from: whiteList1, gas, value: new BigNumber(3.4e19) })
                        assert.equal(txObject.receipt.status, true, "Buying remaining STEWs failed")
                    })
                    it('should verify SaleSTEWBNB has 0 STEWS', async () => {
                        stewBalance = new BigNumber(await stewConInstance.balanceOf.call(saleSTEWBNBConInstance.address))
                        assert.equal(stewBalance.toNumber(), 0, "STEW balance do not match")
                    })
                    it('should verify whiteList1 has 147000 STEWS', async () => {
                        stewBalance = new BigNumber(await stewConInstance.balanceOf.call(whiteList1))
                        assert.equal(stewBalance.toNumber(), 1.47e23, "STEW balance do not match")
                    })
                    it('before withdraw should verify contract balance to be 9800 BNB', async () => {
                        const balanceEth = await balance.current(saleSTEWBNBConInstance.address, 'ether')
                        assert.equal(balanceEth.toNumber(), 9800, "Balances do not match")
                    })
                    it('should withdraw 9800 BNBs', async () => {
                        txObject = await saleSTEWBNBConInstance.withdrawBNBs({ from: owner, gas })
                        assert.equal(txObject.receipt.status, true, "Witndraw BNB failed")
                    })

                    it('after withdraw should verify contract balance to be 0 BNB', async () => {
                        const balanceEth = await balance.current(saleSTEWBNBConInstance.address, 'ether')
                        assert.equal(balanceEth.toNumber(), 0, "Balances do not match")
                    })
                })
            })
        })
    })
})