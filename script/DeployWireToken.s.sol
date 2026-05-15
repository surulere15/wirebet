// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/WireToken.sol";

contract DeployWireToken is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        WireToken wire = new WireToken(deployerAddress);

        vm.stopBroadcast();

        console.log("WireToken deployed to:", address(wire));
    }
}
