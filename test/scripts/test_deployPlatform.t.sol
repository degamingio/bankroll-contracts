// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {DeployPlatform} from "script/deploy-Platform.s.sol";

contract TestDeplyPlatform is Test {
    DeployPlatform deploymentScript;

    function setUp() public {
        deploymentScript = new DeployPlatform();
    }

    function test_deployPlatform() public {
        assertEq(deploymentScript.admin(), vm.addr(vm.envUint("ADMIN_PRIVATE_KEY")));
        assertEq(deploymentScript.token(), vm.envAddress("TOKEN_ADDRESS"));
    }

    function test_run() public {
        deploymentScript.run();
    }
}