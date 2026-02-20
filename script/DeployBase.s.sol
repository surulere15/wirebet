// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../contracts/factory/MarketFactory.sol";
import "../contracts/positions/Positions1155.sol";
import "../contracts/fees/FeeRouter.sol";

/**
 * @title DeployBase
 * @author JOE
 * @notice Foundry script to deploy the Wirebet MVP infrastructure to Base Sepolia or Base Mainnet.
 *
 * Deploys:
 *   1. Positions1155    — shared ERC-1155 for all market position tokens
 *   2. FeeRouter        — shared fee distribution to treasury
 *   3. MarketFactory    — creates market + vault pairs via CREATE2
 *
 * After deployment, call MarketFactory.createMarket() to spin up individual markets.
 */
contract DeployBase is Script {
    // Base Sepolia USDC address
    address constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    // Base Mainnet USDC address
    address constant BASE_MAINNET_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    function run()
        public
        returns (
            MarketFactory factory,
            Positions1155 positions,
            FeeRouter feeRouter
        )
    {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        address usdcAddress;
        if (block.chainid == 8453) {
            usdcAddress = BASE_MAINNET_USDC;
        } else if (block.chainid == 84532) {
            usdcAddress = BASE_SEPOLIA_USDC;
        }
        require(usdcAddress != address(0), "Unsupported chainId for USDC address");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy shared components
        feeRouter = new FeeRouter(deployer);
        positions = new Positions1155();

        // 2. Deploy the factory
        factory = new MarketFactory(
            address(positions),
            address(feeRouter),
            usdcAddress
        );

        // 3. Wire FeeRouter to accept calls from the factory
        feeRouter.setFactory(address(factory));

        // 4. Transfer Positions ownership to the factory so it can grant minter rights
        positions.transferOwnership(address(factory));

        vm.stopBroadcast();

        console.log("--- Wirebet MVP Deployed ---");
        console.log("FeeRouter:     ", address(feeRouter));
        console.log("Positions1155: ", address(positions));
        console.log("MarketFactory: ", address(factory));
        console.log("Collateral:    ", usdcAddress);
        console.log("Deployer:      ", deployer);
    }
}
