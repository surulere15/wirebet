// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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
    using SafeERC20 for IERC20;

    address public treasury;
    address public insuranceFund;
    address public rewardsDistributor;
    address public factory;

    /// @notice Tracks which market addresses are authorized to call routeTradeFee.
    mapping(address => bool) public authorizedMarkets;

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
    event MarketAuthorized(address indexed market, bool authorized);
    event FactorySet(address indexed factory);

    error InvalidAddresses();
    error Unauthorized();
    error FactoryAlreadySet();

    modifier onlyMarketFactory() {
        if (msg.sender != factory) revert Unauthorized();
        _;
    }

    modifier onlyAuthorizedMarket() {
        if (!authorizedMarkets[msg.sender]) revert Unauthorized();
        _;
    }

    constructor(address _initialTreasury) Ownable(msg.sender) {
        if (_initialTreasury == address(0)) revert InvalidAddresses();
        treasury = _initialTreasury;
        emit FeeConfigSet(_initialTreasury, address(0), address(0));
    }

    /**
     * @notice Sets the factory address. Can only be called once by the owner.
     * @param _factory The MarketFactory contract address.
     */
    function setFactory(address _factory) external onlyOwner {
        if (factory != address(0)) revert FactoryAlreadySet();
        if (_factory == address(0)) revert InvalidAddresses();
        factory = _factory;
        emit FactorySet(_factory);
    }

    /**
     * @notice Registers or deregisters a market as authorized to route fees.
     * @dev Only callable by the factory.
     * @param _market The market address.
     * @param _authorized Whether the market is authorized.
     */
    function setAuthorizedMarket(address _market, bool _authorized) external onlyMarketFactory {
        authorizedMarkets[_market] = _authorized;
        emit MarketAuthorized(_market, _authorized);
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
    ) external onlyAuthorizedMarket {
        IERC20(token).safeTransfer(treasury, amount);

        emit FeesRouted(marketId, token, amount);
    }
}
