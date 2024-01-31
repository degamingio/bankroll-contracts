# Bankroll Contracts

## Foundry Installation

```sh
curl -L https://foundry.paradigm.xyz | bash
```

```sh
foundryup
```

see [docs](https://book.getfoundry.sh/getting-started/first-steps)

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
