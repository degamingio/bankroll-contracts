# Bankroll Contracts

## Deployments
| Operator | Environment | Token | Arbitrum Sepolia | XDC Apothem                                                                                                                                   | XDC Mainnet |
|----------|-------------|-------|------------------|-------------                                                                        |-------------| 
| Cap Demo | Development | mUSD  |                  | https://explorer.apothem.network/address/0x442cD67533Efc9519722a4401d0e4d6EBa2A6bf1 |             |
| Cap Demo | Development | mUSDT |                  | https://explorer.apothem.network/address/0xD665D66070f6B7dA3659548521C049967ba7bafD |             |
| Cap Demo | Staging     | mUSD  |                  |                                                                                     |             |
| Cap Demo | Staging     | mUSDT |                  |                                                                                     |             | 

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
