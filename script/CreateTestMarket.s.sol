// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/factory/MarketFactory.sol";
import "../contracts/interfaces/IWirebetMarket.sol";

/**
 * @title CreateTestMarket
 * @notice Creates a test prediction market via the deployed MarketFactory.
 *
 * Usage:
 *   FACTORY_ADDRESS=0x... forge script script/CreateTestMarket.s.sol \
 *     --rpc-url $BASE_SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv
 */
contract CreateTestMarket is Script {
    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address factoryAddr = vm.envAddress("FACTORY_ADDRESS");
        address resolver = vm.addr(deployerKey); // deployer is resolver for MVP

        MarketFactory factory = MarketFactory(factoryAddr);

        vm.startBroadcast(deployerKey);

        bytes32 questionHash = keccak256("Will ETH be above $5,000 on March 31, 2026?");
        uint64 closeTime = uint64(block.timestamp + 2 hours);

        RiskParams memory risk = RiskParams({
            bufferBps: 500,
            feeBps: 100,
            maxTradeSizeUSDC6: 10_000e6,
            maxNetExposureBps: 8000
        });

        uint256 bUSDC6 = 1000e6;

        (address market, address vault) = factory.createMarket(
            questionHash,
            resolver,
            closeTime,
            risk,
            bUSDC6
        );

        vm.stopBroadcast();

        console.log("--- Test Market Created ---");
        console.log("Market:    ", market);
        console.log("Vault:     ", vault);
        console.log("Resolver:  ", resolver);
        console.log("CloseTime: ", closeTime);
        console.log("MarketId:  ");
        console.logBytes32(WirebetMarket(market).marketId());
    }
}
