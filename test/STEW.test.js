const { expectRevert, balance } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const BigNumber = require('bignumber.js');
const STEW = artifacts.require("STEW")

contract('STEW is [ERC720, Ownable]', (accounts) => {
    const [owner, acc1] = accounts
    const gas = 6721975
    const fixedSupply = "0x2c781f708c50a0000000" // 210000 STEW Coins

    let stewConInstance;
    let txObject;

    describe('STEW tests', () => {
        before(async () => {
            stewConInstance = await STEW.new(fixedSupply, { from: owner, gas })
        })

        context('checks constructor invocation is successful', () => {
            let name, symbol, tokenDecimals, totalSupply;
            it('should have token name to be `StewCoin`', async () => {
                name = await stewConInstance.name.call()
                assert.equal(name, 'StewCoin', "Token name do not match")
            })
            it('should have token symbol to be `STEW`', async () => {
                symbol = await stewConInstance.symbol.call()
                assert.equal(symbol, 'STEW', "Token symbol do not match")
            })
            it('should have token tokenDecimals to be 18', async () => {
                tokenDecimals = await stewConInstance.decimals.call()
                assert.equal(tokenDecimals, 18, "Token decimals do not match")
            })
            it('should verify totalSupply is 210000', async () => {
                totalSupply = new BigNumber(await stewConInstance.totalSupply.call());
                assert.equal(totalSupply.toNumber(), fixedSupply, "Total supply do not match")
            })
        })

        context('updateDecimals', () => {
            const actualTokenDecimals = 18;
            const updatedTokenDecimals = 8;
            let decimals;
            it('reverts when updateDecimals is invoked by non-owner', async () => {
                await expectRevert(
                    stewConInstance.updateDecimals(updatedTokenDecimals, { from: acc1, gas }),
                    "Ownable: caller is not the owner"
                )
            })
            it('before update tokenDecimals is 18', async () => {
                decimals = await stewConInstance.tokenDecimals.call()
                assert.equal(decimals, actualTokenDecimals, "Token decimals do not match")
            })
            it('updates token decimals when invoked by owner', async () => {
                txObject = await stewConInstance.updateDecimals(updatedTokenDecimals, { from: owner, gas })
                assert.equal(txObject.receipt.status, true, "Update token decimals failed")
            })
            it('after update tokenDecimals is 8', async () => {
                decimals = await stewConInstance.decimals.call()
                assert.equal(decimals, updatedTokenDecimals, "Token decimals do not match")
            })
            it('sets the tokenDecimals to actualTokenDecimals', async () => {
                txObject = await stewConInstance.updateDecimals(actualTokenDecimals, { from: owner, gas })
                assert.equal(txObject.receipt.status, true, "Update token decimals failed")
            })
        })

        context('burn', () => {
            let balance;
            const burnAmount = new BigNumber(1e21) // 1000
            it("before burn account balance is 210000", async () => {
                balance = new BigNumber(await stewConInstance.balanceOf.call(owner));
                assert.equal(balance.toNumber(), 2.1e23, "Balance do not match")
            })
            it('burns 10000 STEW coins of account', async () => {
                txObject = await stewConInstance.burn(owner, burnAmount, { from: owner, gas })
                assert.equal(txObject.receipt.status, true, "Token burn failed")
            })
            it("after burn account balance is 200000", async () => {
                balance = new BigNumber(await stewConInstance.balanceOf.call(owner));
                assert.equal(balance.toNumber(), 2.0900000000000002e+23, "Balance do not match")
            })
        })

        context('withdrawAll', () => {
            it('sends 1 ether to the contract', async () => {
                txObject = await stewConInstance.send(new BigNumber(1e18), { from: owner, gas })
                assert.equal(txObject.receipt.status, true, "Ether send failed")
            })

            it('should verify contract balance to be 1 Eth', async () => {
                const balanceEth = await balance.current(stewConInstance.address, 'ether')
                assert.equal(balanceEth.toNumber(), 1, "Balances do not match")
            })

            it('should withdraw 1 Eth from the contract', async () => {
                txObject = await stewConInstance.withdrawAll({ from: owner, gas })
                assert.equal(txObject.receipt.status, true, "Withdraw failed")
            })

            it('after withdraw should verify contract balance to be 0 Eth', async () => {
                const balanceEth = await balance.current(stewConInstance.address, 'ether')
                assert.equal(balanceEth.toNumber(), 0, "Balances do not match")
            })
        })
    })
})