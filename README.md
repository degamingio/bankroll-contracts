# Bankroll Contracts

### Arbitrum sepolia:

```sh
Bankroll:             0x0555034417990A6F8E57A0B8f5C656e0d6ceef2a
BankrollImpl:         0xc1D21B91176bB7A248bc36EaDa8d789D2714B4a3
DGBankrollFactory:    0x8c2fb590C91E252391ae9796641A956B9BC519dD
DGBankrollManager:    0xCCd4bD4BAa8059f2e70b97B43354b0519a1a39A0
DGEscrow:             0xEbeaCA3067EDED4718C648B848C68642eA780061
ProxyAdmin:           0x720B0a5DbB718c9F7ba5211a1d16f9067ace23CE
```

### Blast sepolia:

```sh
Bankroll:             0x55E24dD6056d676698767CaA4715B6ddB0CE5CA7
BankrollImpl:         0xae07315a09A37CaB9fC80AD6f2078D06E7A44076
DGBankrollFactory:    0x442cD67533Efc9519722a4401d0e4d6EBa2A6bf1
DGBankrollManager:    0x97fcd67cE8374f94601A0524C423e9b9F8C0c210
DGEscrow:             0x99bb8a97aea843c0d27Fe2703a39dC187A9c6070
ProxyAdmin:           0x961dEaA828Aad47d20f49965da81421E21D85618

```
### XDC Apothem:

```sh
Bankroll MUSD:        0xbB0ee0e1f119328b1E012C029c0dF46E74d24D41
Bankroll MUSDT:       0x242f2d72f6B9F534B6182d911e719b7be7a81861
BankrollImpl:         0x75fd9A70eF232a415D8Ae04C5631E3dF4FD801b0
DGBankrollFactory:    0x1e45b6C4f00e63A6771e70DDaDd1b2B2182aC31c
DGBankrollManager:    0x6637AeAc61D5f1B5a190A5c510ab88fa0E414F76
DGEscrow:             0x180Fa63d9759ce8ab916F1f7bC8C8989De07906b
ProxyAdmin:           0x8c2fb590C91E252391ae9796641A956B9BC519dD
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