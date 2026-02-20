// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./WirebetTypes.sol";

/*//////////////////////////////////////////////////////////////
// MARKET
//////////////////////////////////////////////////////////////*/

interface IBinaryMarket {
    /*==================== Events ====================*/
    event Trade(
        address indexed user,
        WirebetTypes.Outcome indexed outcome, // YES/NO
        bool indexed isBuy,
        uint256 collateralInOrOut, // in on buy; out on sell
        uint256 sharesInOrOut, // out on buy; in on sell
        uint256 feePaid,
        uint256 priceBefore, // optional: scaled price snapshot (implementation-defined)
        uint256 priceAfter // optional
    );
    event MarketClosed(address indexed by);
    event MarketResolved(address indexed by, WirebetTypes.Outcome outcome);
    event MarketCancelled(address indexed by, string reason);
    event Redeemed(
        address indexed user,
        WirebetTypes.Outcome indexed outcome, // shares redeemed
        uint256 sharesIn,
        uint256 collateralOut
    );
    event FeesRouted(address indexed treasury, uint256 amount);
    event PoolSynced(uint256 poolYes, uint256 poolNo); // after liquidity/trades
    event Paused(address indexed by);
    event Unpaused(address indexed by);

    /*==================== Errors ====================*/
    error Unauthorized();
    error NotOpen();
    error NotClosed();
    error NotResolved();
    error NotCancellable();
    error AlreadyResolved();
    error AlreadyClosed();
    error AlreadyCancelled();
    error InvalidOutcome();
    error InvalidAmount();
    error SlippageExceeded();
    error CloseTimeNotReached();
    error ZeroAddress();
    error FeeTooHigh();
    error CollateralMismatch();

    /*==================== Immutable / Config ====================*/
    function factory() external view returns (address);
    function feeTreasury() external view returns (address);
    function questionHash() external view returns (bytes32);
    function openTime() external view returns (uint64);
    function closeTime() external view returns (uint64);
    function collateral() external view returns (address);
    function feeBps() external view returns (uint16);
    function resolver() external view returns (address);
}
