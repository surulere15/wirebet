// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWirebetMarket.sol"; // For error types and structs

/**
 * @title FeeRouter
 * @author JOE
 * @notice A contract to distribute trade fees to the treasury, stakers, and insurance fund.
 * - This MVP implementation simply forwards all fees to a treasury address.
 * - The full fee split logic will be implemented in v2.
 * - Ownable, with restricted access to core functions.
 */
contract FeeRouter is Ownable {
    address public treasury;
    address public insuranceFund;
    address public rewardsDistributor;

    // In v2, this would be a mapping per marketId. For MVP, we use a global split.
    // WB.FeeSplit public globalFeeSplit;

    event FeeConfigSet(
        address indexed treasury,
        address indexed insurance,
        address indexed rewards
    );
    event FeesRouted(
        bytes32 indexed marketId,
        address indexed token,
        uint256 amount
    );

    error InvalidAddresses();
    error Unauthorized();

    modifier onlyMarketFactory() {
        // In a real implementation, the factory would be set at construction
        // and this modifier would check msg.sender == factory.
        // For the MVP, we'll keep it simple and rely on Ownable for config.
        _;
    }

    constructor(address _initialTreasury) Ownable(msg.sender) {
        if (_initialTreasury == address(0)) revert InvalidAddresses();
        treasury = _initialTreasury;
        emit FeeConfigSet(_initialTreasury, address(0), address(0));
    }

    /**
     * @notice Sets the destination addresses for the fee components.
     * @dev Only callable by the owner.
     */
    function setFeeConfig(
        address _treasury,
        address _insurance,
        address _rewards
    ) public onlyOwner {
        if (_treasury == address(0)) revert InvalidAddresses();
        treasury = _treasury;
        insuranceFund = _insurance;
        rewardsDistributor = _rewards;
        emit FeeConfigSet(_treasury, _insurance, _rewards);
    }

    /**
     * @notice Receives and routes a trade fee from a market contract.
     * @dev In the MVP, all fees are sent directly to the treasury.
     * @param marketId The ID of the market where the fee was generated.
     * @param token The collateral token the fee is denominated in.
     * @param amount The amount of the fee.
     */
    function routeTradeFee(
        bytes32 marketId,
        address token,
        uint256 amount
    ) external {
        // For the MVP, we assume the market contract has already received the
        // fee and is now transferring it to this router.
        // In a full implementation, you'd add an onlyMarket modifier.
        
        IERC20(token).transfer(treasury, amount);

        emit FeesRouted(marketId, token, amount);
    }
}
