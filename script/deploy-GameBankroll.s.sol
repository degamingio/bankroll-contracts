// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {GameBankroll} from "src/GameBankroll.sol";
import {MockToken} from "test/mock/MockToken.sol";

contract DeployGameBankroll is Script {
    address mUSD = 0xb0F5c667e9aB3144cF6b2E9B03805a87955bdC07;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new GameBankroll(mUSD, msg.sender);

        vm.stopBroadcast();
    }
}
