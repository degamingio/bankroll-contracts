// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {Bankroll} from "src/Bankroll.sol";
import {DGBankrollManager} from "src/DGBankrollManager.sol";
import {DGBankrollFactory} from "src/DGBankrollFactory.sol";

contract CreateBankroll is Script {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    uint256 operatorPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");

    address operator = vm.addr(operatorPrivateKey);

    address token = vm.envAddress("TOKEN_ADDRESS");

    DGBankrollManager dgBankrollManager = DGBankrollManager(
        // ADDRESS HERE
        0xA5417198E91d97cE3CeB9Df06dCAa0fb5654cfe6
    );

    DGBankrollFactory dgBankrollFactory = DGBankrollFactory(
        // ADDRESS HERE
        0xD0F2a5FAf981773fF6f912e762E831Fb936D9E71
    );
    
    address deGaming = 0x1d424382e8e09CC6F8425c9F32D2c695E7698db7;
    
    uint256 maxRisk = 10_000;
    uint256 lpFee = 650;

    function run() public {
        //console.log("Deployer:          ", vm.addr(deployerPrivateKey));
        //console.log("Token:             ", token);
        //console.log("Operator:          ", operator);
        //console.log("DGBankrollManager: ", address(dgBankrollManager));
        //console.log("DGBankrollFactory: ", address(dgBankrollFactory));

        vm.startBroadcast(deployerPrivateKey);

        dgBankrollFactory.deployBankroll(
            address(token), 
            maxRisk, 
            "0x0"
        );

        address bankrollAddr = dgBankrollFactory.bankrolls(dgBankrollFactory.bankrollCount() - 1);

        Bankroll bankroll = Bankroll(bankrollAddr);

        dgBankrollManager.setOperatorToBankroll(address(bankroll), operator);
        dgBankrollManager.approveBankroll(address(bankroll), lpFee);

        bankroll.maxBankrollManagerApprove();
        vm.stopBroadcast();
    } 
}