// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
// FACTORY
//////////////////////////////////////////////////////////////*/

interface IMarketFactory {
    /*==================== Events ====================*/
    event MarketCreated(
        address indexed market,
        address indexed collateral,
        bytes32 indexed questionHash,
        uint64 closeTime,
        address creator,
        address resolver
    );
    event FeeTreasurySet(address indexed treasury);
    event DefaultFeeBpsSet(uint16 feeBps);
    event MarketImplementationSet(address indexed implementation);
    event Paused(address indexed by);
    event Unpaused(address indexed by);

    /*==================== Errors ====================*/
    error Unauthorized();
    error InvalidParams();
    error InvalidFeeBps();
    error InvalidTime();
    error CollateralNotAllowed();
    error MarketAlreadyExists(bytes32 marketKey);
    error ZeroAddress();

    /*==================== View ====================*/
    function feeTreasury() external view returns (address);
    function defaultFeeBps() external view returns (uint16);

    /// Optional allowlist; if you don’t want allowlist, return true for all in implementation.
    function isCollateralAllowed(address collateral)
        external
        view
        returns (bool);

    /// Deterministic key to prevent duplicates (e.g., keccak256(questionHash, closeTime, collateral))
    function computeMarketKey(
        bytes32 questionHash,
        uint64 closeTime,
        address collateral
    ) external pure returns (bytes32);

    function getMarket(bytes32 marketKey) external view returns (address market);
    function allMarketsLength() external view returns (uint256);
    function allMarkets(uint256 index) external view returns (address);

    /*==================== Admin ====================*/
    function setFeeTreasury(address treasury) external;
    function setDefaultFeeBps(uint16 feeBps) external;

    /// Optional (if using minimal proxy/clones)
    function setMarketImplementation(address implementation) external;

    /// Optional collateral allowlist controls
    function setCollateralAllowed(address collateral, bool allowed) external;
    function pause() external;
    function unpause() external;

    /*==================== Create ====================*/
    /**
     * @notice Create a new binary market instance.
     * @dev Implementations often deploy a minimal proxy clone of a Market implementation.
     * @return market The deployed market address
     */
    function createMarket(bytes calldata params)
        external
        returns (address market);
}
