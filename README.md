# basketcoin-sc

List of smart contracts for Basketcoin

# For Testnet

- Open remix online compiler [Remix](https://remix.ethereum.org/#optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.1+commit.df193b15.js)

- In the file explorer, on the left-hand side, `contracts` -> right click -> `New File` -> `STEW.sol` -> Paste `/flattened_contracts/STEW.sol` -> `Ctrl+s`

Do the above steps for `BNB.sol` & `SaleSTEWBNB.sol`

- Compile the contracts (`Blue Button`)

- From the left-panel, click `Deploy & run transactions`

- For BNB.sol -> Deploy -> specify the initialSupply value, you can use `0x33b2e3c9fd0804000000000` => 1 Billion BNB Coins

- For STEW.sol -> Deploy -> specify the fixedSupply value, you can use `0x2c781f708c50a0000000` => 210000 STEW Coins

- For SaleBNBSTEW.sol -> Deploy -> specify the BNB & STEW contract addresses

# For Mainnet

- We can follow above steps or we can also add scripts in the package json for mainnet deployment

# Flattening contracts

Execute from the root of the project:

`truffle-flattener contracts/STEW.sol --output flattened_contracts/STEW.sol`
