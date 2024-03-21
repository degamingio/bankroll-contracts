# Bankroll Contracts

Bankroll:             0x54bE4777F127019B4E3Fb9E31cf8FAB19287d662
BankrollImpl:         0xa37ec425f96D9531dD597Ec8932Df8c484B8Eaf2
DGBankrollFactory:    0x09a40dbb12cA3E06e92F75b21FdBd4994728947D
DGBankrollManager:    0x343f864EAf4A27706ffD29c6CCf990b2934F1E00
DGEscrow:             0x5A44Ad2BEdb5f4CE6041706aCAcfF8755D7a96d8
ProxyAdmin:           0x2f0DDeCC93c2066621951910B41D669162ba2892

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