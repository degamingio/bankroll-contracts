# Bankroll Contracts

## Address Registry :

Latest deployed contract address

### XDC APOTHEM:

| Contract           | Address                                     | Explorer                                                                             |
| ------------------ | ------------------------------------------- | ------------------------------------------------------------------------------------ |
| Aviatrix      | 0x66D2eFDf57127e7187F1A13598bB2B3ecba87C9E | https://explorer.apothem.network/address/xdc66D2eFDf57127e7187F1A13598bB2B3ecba87C9E |

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
```
