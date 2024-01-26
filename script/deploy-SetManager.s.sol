// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {Bankroll} from "src/Bankroll.sol";
import {MockToken} from "test/mock/MockToken.sol";

contract SetManager is Script {
    function run() public {
        // uint256 managerPrivateKey = vm.envUint("MANAGER_PRIVATE_KEY");
        // address manager = vm.envAddress("MANAGER_ADDRESS");
        // address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        // MockToken token = MockToken(tokenAddress);
        // Bankroll bankroll = Bankroll(
        //     0xF2E2ef600507Ef844C6166BFB6c0dBE7A22F6eDa
        // );
        // // Set manager
        // vm.startBroadcast(managerPrivateKey);
        // token.approve(
        //     address(bankroll),
        //     0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        // ); //max int value
        // vm.stopBroadcast();
    }
}
