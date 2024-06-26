# DeGaming Bankroll Contracts

This is the repository of DeGamings bankroll contracts.
Please see our [audit](/audit/) or head straight to our [contracts](/src/) for more information. Contributions are welcome.

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

## Steps to deploy bankroll:

### Deploy Platform:

This is the first step which deploys the bankroll environment but not the actual bankroll

```sh
forge script script/deploy-Platform.s.sol --broadcast --legacy --verify --slow --rpc-url <NETWORK>

```

### Deploy Bankroll:

After the platform in created, 


```sh
forge script script/utils/create-Bankroll.s.sol --broadcast --legacy --slow --rpc-url <NETWORK>
```

## The Deployment folder
The latest deployment addresses one each chain will be stored in the [deployment folder](/deployment/). This way you can copy these addresses to a local file or paste it into the readme to keep track of deployment, as well as using the [util scripts](/script/utils/) for admin tasks as long as the correct addresses are in the deployment folder

## Prod:

### Mode
```sh
Bankroll:             0x3C046e16494cbeA2e92ab6BaA95d5a5e0fD66930
Bankroll BetMode:     0xeb5D5af6a0ac3B64243858094d6b3b379B8772Aa
BankrollImpl:         0x953C49d2A2678Eb9c52D00601ff31579Daad6885
DGBankrollFactory:    0x34A13c722E2b6247EA431E605a145Ca0DEdD2977
DGBankrollManager:    0xFB75F39166C006254931d314A24397979440dE73
DGEscrow:             0xd245C96879E3d7115ac7d9c667B3070a531CB439
ProxyAdmin:           0x9eFCb65C3287f1206102708277689983877fE10b
```

### Base:

```sh
Bankroll WAGMI:       0xd824d295Cb5B16d68E4d5901B09D45782bFc37FE
BankrollImpl:         0xDB8aa4f087c7954cDc4aF6c241a8A99e15dD8fE3
DGBankrollFactory:    0xB0465168B7F278F38cF4b4Cf89227CeF24611b5d
DGBankrollManager:    0x2C8dB7776Abe62fA6B51CF404c8af7B527c3D984
DGEscrow:             0xF2E2ef600507Ef844C6166BFB6c0dBE7A22F6eDa
ProxyAdmin:           0xd1258dB334EA9Fe2c534D4f5E94940dE95C5Fd06
```

### Arbitrum:

```sh
Bankroll WAGMI:       0xF7386317256cEffcD55EdCE0aDF2ce1cBFbB1A35
Bankroll:             0xaa7904F6DF856e681FeA8DaC17D70038B9b1e312
BankrollImpl:         0xAA89FaccA3483A6434aC422D24Cc17148AbA7695
DGBankrollFactory:    0x54Aa9fD70Bf24A6a88a324D0745abC93B9982343
DGBankrollManager:    0x7D389AF6F4d5F9288Fb52e4f79C0ba0dA085e216
DGEscrow:             0x7711BEEEb2eD3fb49c5c3C5760de95A98dd065D5
ProxyAdmin:           0xE8F4827214AE5E98e9Ecb37F902D49727eb61D45
```

### Blast:

```sh
Bankroll:             0x95487803c405F7fe30c97b77D190f1CFC9646e3C
BankrollImpl:         0xDA2614E4a44c06f21533d848c5c9445F42641aB2
DGBankrollFactory:    0x51D77Cb2d8a76350D3bb01d01d3E2BdFe9Df42Cc
DGBankrollManager:    0xb762Da363862A319E0A4Ab93C3D9dBBC1A3bE401
DGEscrow:             0x5f0D8A3e8e5990CFb23795645e6849b83fc60726
ProxyAdmin:           0xE6e10A8a573f68A24A53DEbCFe6546821a04E6f9
```

### XDC:

```sh
Bankroll:             0x4d57a0743cd79F15B63E509e618B8f9BF193A265
BankrollImpl:         0x3CF4F73356f2f46B4DBC40Bc3e5405fbC7509717
DGBankrollFactory:    0x836Fb23d69c0fa1f195d1FDB25742E30ded5A328
DGBankrollManager:    0x5A44Ad2BEdb5f4CE6041706aCAcfF8755D7a96d8
DGEscrow:             0xa37ec425f96D9531dD597Ec8932Df8c484B8Eaf2
ProxyAdmin:           0x76e5195c7d09C2fCeAB4CB8EA6a54b362De655da
```

## Dev:

### Arbitrum sepolia:

```sh
Bankroll:             0x79cb297c923430cfab2714648941553298444743
BankrollImpl:         0x682582ED7d10Db0f2210f9B14d33e4106117223C
DGBankrollFactory:    0x71A5Cd9c9909dBf2c20445E7168875712094e76B
DGBankrollManager:    0xd2fb0A58d2E25b4d7D8fA3f9aeF8AD7119414141
DGEscrow:             0x616659a5aEDcF3c291b0c5f57D83dB48d8333393
ProxyAdmin:           0xd2B316B383f472312453D8c012cBe309392705d0
```

### Blast sepolia:

```sh
Bankroll:             0xbF5AD084547a5Ba83822f20AeaaCE87d8CC2E7a1
BankrollImpl:         0x06B93c503eC39cD45c8664190c6d2663365Bf45c
DGBankrollFactory:    0xF0FE256f315FFCBd713c6904E33311e1D528aF99
DGBankrollManager:    0xDA2614E4a44c06f21533d848c5c9445F42641aB2
DGEscrow:             0x51D77Cb2d8a76350D3bb01d01d3E2BdFe9Df42Cc
ProxyAdmin:           0x4F3DF10e5e800A1990ED38fB814202a10611E4Af

```
### XDC Apothem:

```sh
Bankroll MUSD:        0xe758D37ee043e250c56127bDe6312e8F31A960cC
Bankroll MUSDT:       0xB58e49823f1E539b84Eda034f506E5e30CdDff21
BankrollImpl:         0x8a0F1D5261e5a3467037E7B4cE53Fc0498f4B60f
DGBankrollFactory:    0x485C43f6ea086af34476d15954a4A92EF32fb2DC
DGBankrollManager:    0xB3b4EE2ac46D283aF39caB76a4aF488E679b7C39
DGEscrow:             0xC4a4C50945F9D44044C5F005Fc327C9a5bceEf88
ProxyAdmin:           0x65119C1Ef94F7A228a0B142040Fa8219B4b1C320
```

## Staging:

### Arbitrum sepolia:

```sh
Bankroll:             0xa0e7B78C2990d5E0Ce185A5Ba565388639a33e7B
BankrollImpl:         0xef4ae4fc48B01a7816AE13A92217BD085C8409B4
DGBankrollFactory:    0x91E01407D5d17EB2462E1E082D07B43B88577E5c
DGBankrollManager:    0xEcda7dFa3032b00Daa294FDed3A1F1348759A9Ca
DGEscrow:             0x1A9D4f05a06E79ee941008526C84AAca91bfef29
ProxyAdmin:           0x68ec0E6CDc72260Fd814D1f27dBfc467317b1c53
```

### Blast sepolia:

```sh
Bankroll:             0xe662A6b3D093e53C6910F05E2122e8F4C92864F1
BankrollImpl:         0x1A9D4f05a06E79ee941008526C84AAca91bfef29
DGBankrollFactory:    0x51Db97f0a5ef75ecdA70938306d0cEa894BBE1Ee
DGBankrollManager:    0x5dA8888d11131753b98FF702B4140F09fB1c55cE
DGEscrow:             0x8A84d11C3757008A8d76DE6C76Bf686460c4a5d9
ProxyAdmin:           0x2bd4C36B32FdEb37805431bAe057F231e3fd0853

```
### XDC Apothem:

```sh
Bankroll MUSD 0:      0x0Ee7f2EB56ea60c07EdE80d47b1BAc9496b4d809
Bankroll MUSD 1:      0x7E87520AB349abB3368Ce3EA594303B548fa9Edb
Bankroll MUSD 2:      0xa9226D46445435a051fd54266bbD122db6195ed5
BankrollImpl:         0x72E0068d6AED2055d09314bB7444ED770f512dEB
DGBankrollFactory:    0xEbDb3D71dB8Cd40c7C442aE2c6E346a2EC51555e
DGBankrollManager:    0x51Db97f0a5ef75ecdA70938306d0cEa894BBE1Ee
DGEscrow:             0xac1684E1e51aaA47353004040C0E5C51Ce31E3F4
ProxyAdmin:           0x1A9D4f05a06E79ee941008526C84AAca91bfef29
```

