# Bankroll Contracts

## Deployments
| Operator   | Environment | Token | Arbitrum Sepolia | XDC Apothem                                                                         | XDC Mainnet |
|----------  |-------------|-------|------------------|-------------                                                                        |-------------| 
| Cap Demo   | Development | mUSD  |                  | https://explorer.apothem.network/address/0x442cD67533Efc9519722a4401d0e4d6EBa2A6bf1 |             |
| Cap Demo   | Development | mUSDT |                  | https://explorer.apothem.network/address/0xD665D66070f6B7dA3659548521C049967ba7bafD |             |
| Cap Demo   | Staging     | mUSD  |                  | https://explorer.apothem.network/address/0x23e063325d97e673371efdc61892ed082f0d7798 |             |
| Cap Demo   | Staging     | mUSDT |                  | https://explorer.apothem.network/address/0xa91D065a70Ec3fbbb5daE95b75BA0E85e95eD264 |             |
| Wagmi Beta | Development | mUSD  |                  | https://explorer.apothem.network/address/0x4c3bd19d2bc83dbb2f7bf71f8294fc831e25396f |             |
| Wagmi Beta | Development | mUSDT |                  | https://explorer.apothem.network/address/0xd6de698dac40aa6604f4e65b117de0ec0175cc9f |             |
| Wagmi Beta | Staging     | mUSD  |                  | https://explorer.apothem.network/address/0xe6e10a8a573f68a24a53debcfe6546821a04e6f9 |             |
| Wagmi Beta | Staging     | mUSDT |                  | https://explorer.apothem.network/address/0x744bfc18d1e96c7cc933f1fa92da1e2e12fe0bc8 |             |
| Wagmi Beta | Prod        | USDT  |                  |                                                                                     |             |
| KOC        | Development | mUSD  |                  | https://explorer.apothem.network/address/0xb762da363862a319e0a4ab93c3d9dbbc1a3be401 |             |
| KOC        | Development | mUSDT |                  | https://explorer.apothem.network/address/0x4F3DF10e5e800A1990ED38fB814202a10611E4Af |             |
| KOC        | Staging     | mUSD  |                  | https://explorer.apothem.network/address/0x5f0D8A3e8e5990CFb23795645e6849b83fc60726 |             | 
| KOC        | Staging     | mUSDT |                  | https://explorer.apothem.network/address/0xda2614e4a44c06f21533d848c5c9445f42641ab2 |             | 
| KOC        | Prod        | USDT  |                  |                                                                                     |             |    

## Compile Project

```sh
forge build
```

## Execute Tests

```sh
forge test -vvv
```

## Deploy Contracts

Initialize `.env` file

```sh
source .env
```

Deploy Bankroll

```sh
forge script script/deploy-Bankroll.s.sol:DeployBankroll --broadcast --legacy --rpc-url https://erpc.apothem.network

forge script script/deploy-Bankroll.s.sol:DeployBankroll --broadcast --legacy --rpc-url https://rpc.xinfin.network
```
