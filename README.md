# Bankroll Contracts

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

### XDC
#### Deploy Platform:

This is the first step which deploys the bankroll environment but not the actual bankroll

```sh
forge script script/deploy-Platform.s.sol --broadcast --legacy --rpc-url xdc-mainnet

forge script script/deploy-Platform.s.sol --broadcast --legacy --rpc-url xdc-apothem
```

#### Deploy Bankroll:

This is the step required to deploy the actuall bankroll  
__IMPORTANT!!!__  
If you are deploying multiple bankrolls on one chain from the same environment (sharing bankroll manager, escrow etc)
make sure to go to the file [create-Bankroll](script/utils/create-Bankroll.s.sol) line 73 and increment the hex salt:  
__first bankroll:__  "0x0"  
__second bankroll:__ "0x1"  
__third bankroll:__  "0x2"  
etc...  

```sh
forge script script/utils/create-Bankroll.s.sol --broadcast --legacy --rpc-url xdc-mainnet

forge script script/utils/create-Bankroll.s.sol --broadcast --legacy --rpc-url xdc-apothem
```

### Arbitrum
#### Note:
Make sure to have added __Blast__ and __Arbitrum__ etherscan api keys to the [.env file](.env.example) prior to deploying on these chains for the easiest contract verification

#### Deploy Platform:

This is the first step which deploys the bankroll environment but not the actual bankroll

```sh
forge script script/deploy-Platform.s.sol --broadcast --rpc-url arbitrum --verify

forge script script/deploy-Platform.s.sol --broadcast --rpc-url arbitrum-sepolia --verify
```

#### Deploy Bankroll:

This is the step required to deploy the actuall bankroll  
__IMPORTANT!!!__  
If you are deploying multiple bankrolls on one chain from the same environment (sharing bankroll manager, escrow etc)
make sure to go to the file [create-Bankroll](script/utils/create-Bankroll.s.sol) line 73 and increment the hex salt:  
__first bankroll:__  "0x0"  
__second bankroll:__ "0x1"  
__third bankroll:__  "0x2"  
etc...  

```sh
forge script script/utils/create-Bankroll.s.sol --broadcast --rpc-url arbitrum --verify

forge script script/utils/create-Bankroll.s.sol --broadcast --rpc-url arbitrum-sepolia --verify
```

### Blast
#### Note:
Make sure to have added __Blast__ and __Arbitrum__ etherscan api keys to the [.env file](.env.example) prior to deploying on these chains for the easiest contract verification

#### Deploy Platform:

This is the first step which deploys the bankroll environment but not the actual bankroll

```sh
forge script script/deploy-Platform.s.sol --broadcast --rpc-url blast --verify

forge script script/deploy-Platform.s.sol --broadcast --rpc-url blast-sepolia --verify
```

#### Deploy Bankroll:

This is the step required to deploy the actuall bankroll  
__IMPORTANT!!!__  
If you are deploying multiple bankrolls on one chain from the same environment (sharing bankroll manager, escrow etc)
make sure to go to the file [create-Bankroll](script/utils/create-Bankroll.s.sol) line 73 and increment the hex salt:  
__first bankroll:__  "0x0"  
__second bankroll:__ "0x1"  
__third bankroll:__  "0x2"  
etc...  

```sh
forge script script/utils/create-Bankroll.s.sol --broadcast --rpc-url blast --verify

forge script script/utils/create-Bankroll.s.sol --broadcast --rpc-url blast-sepolia --verify
```

## The Deployment folder
The latest deployment addresses one each chain will be stored in the [deployment folder](/deployment/). This way you can copy these addresses to a local file or paste it into the readme to keep track of deployment, as well as using the [util scripts](/script/utils/) for admin tasks as long as the correct addresses are in the deployment folder
