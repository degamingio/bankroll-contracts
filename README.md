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
| Wagmi Beta | Prod        | USDT  |                  |                                                                                     | https://xdcscan.io/address/xdcd0ba9abc3e9a671cc430a668cdf4569e910ab2fa |
| KOC        | Development | mUSD  |                  | https://explorer.apothem.network/address/0xb762da363862a319e0a4ab93c3d9dbbc1a3be401 |             |
| KOC        | Development | mUSDT |                  | https://explorer.apothem.network/address/0x4F3DF10e5e800A1990ED38fB814202a10611E4Af |             |
| KOC        | Staging     | mUSD  |                  | https://explorer.apothem.network/address/0x5f0D8A3e8e5990CFb23795645e6849b83fc60726 |             | 
| KOC        | Staging     | mUSDT |                  | https://explorer.apothem.network/address/0xda2614e4a44c06f21533d848c5c9445f42641ab2 |             | 
| KOC        | Prod        | USDT  |                  |                                                                                     | https://xdcscan.io/address/xdc211bc7fb77b64c6e7826810f20498e71f6d56014 |
| Zizi       | Staging     | mUSD  |                  | https://explorer.apothem.network/address/0xbeed2a87dd796991cadea33e1df17ee7c37e9da9 |             |
| Zizi       | staging     | mUSDT |                  | https://explorer.apothem.network/address/0x51d77cb2d8a76350d3bb01d01d3e2bdfe9df42cc |             |
| Zizi       | Production  | USDT  |                  |                                                                                     | https://xdcscan.io/address/xdc5e2af95f0490fd3e9057d7247e0e69ab2c75d798 |
| Raja       | Development | mUSD  |                  | https://explorer.apothem.network/address/0x06b93c503ec39cd45c8664190c6d2663365bf45c |             |
| Raja       | Development | mUSDT |                  | https://explorer.apothem.network/address/0xc99e61443689742a36fbeaa6da5e1ec06ee93a52 |             | 
| Raja       | Staging     | mUSD  |                  | https://explorer.apothem.network/address/0xf0fe256f315ffcbd713c6904e33311e1d528af99 |             | 
| Raja       | Staging     | mUSDT |                  | https://explorer.apothem.network/address/0x720624c87292b7a4792e6237682aa699199caff8 |             | 
| Raja       | Prod        | USDT  |                  |                                                                                     | https://xdcscan.io/address/xdcf60f191da9455756648db724976d9011219dfd11 |
| Casin0x   | Development | mUSD  |                  | https://explorer.apothem.network/address/0x038aB83c4E3C7BBFeEbaEfD27E8974785FC8FCF7 |             |
| Casin0x   | Development | mUSDT |                  | https://explorer.apothem.network/address/0xeafd5b5c8d56ca3b898ebe48bc976283f0909f37 |             |
| Casin0x   | Staging     | mUSD  |                  | https://explorer.apothem.network/address/0x544aa2ed39773ba470dba4b0884a5222d220b3a7 |             |
| Casin0x   | Staging     | mUSDT |                  | https://explorer.apothem.network/address/0x05fb034b05d42abd5deeead5c528e42cf465629a |             |
| Casin0x   | Production  | USDT  |                  |                                                                                     | https://xdcscan.io/address/xdcb6e7daef92c0ba5420ea2c394f9f654f259ec6c4 | 

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

Deploy Platform

```sh
forge script script/deploy-Platform.s.sol:DeployPlatform --broadcast --legacy --rpc-url xdc-mainnet
```