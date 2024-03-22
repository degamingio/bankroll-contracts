# Bankroll Contracts

### These are deployed on arbitrum sepolia testnet

```sh
Bankroll:             0x242f2d72f6B9F534B6182d911e719b7be7a81861
BankrollImpl:         0x4Fa81D1ee764f5e6E33735b43bbFc17927531717
DGBankrollFactory:    0xED16f52959b21CC138DEeA8889Fba13841BFba75
DGBankrollManager:    0xa99F38851444a3728f7F7D702169AFD4e87a6C3C
DGEscrow:             0xa66271c90e344c6be44C3ECe3856Ed9976136fF5
ProxyAdmin:           0x5AD4E55c55DA23B9fF75febf2E16Ce117B334112
```
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