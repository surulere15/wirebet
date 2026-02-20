// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFeeRouter.sol";

enum State { OPEN, LOCKED, RESOLVED, CANCELLED }
enum Result { UNSET, YES, NO, CANCELLED }
enum Side { YES, NO }

struct RiskParams {
    uint16 bufferBps;
    uint16 feeBps;
    uint256 maxTradeSizeUSDC6;
    uint16 maxNetExposureBps;
}

interface IWirebetMarket {
    // --- Events ---
    event TradeExecuted(address indexed trader, Side side, bool isBuy, uint256 collateral, uint256 shares, uint256 fee);
    event StateChanged(State from, State to);
    event Redeemed(address indexed user, Side side, uint256 sharesIn, uint256 collateralOut);
    event FeesSwept(uint256 amount);

    // --- Immutables ---
    function marketId() external view returns (bytes32);
    function collateral() external view returns (IERC20);
    function feeRouter() external view returns (IFeeRouter);
    function resolver() external view returns (address);
    function closeTime() external view returns (uint64);

    // --- State ---
    function state() external view returns (State);
    function result() external view returns (Result);

    // --- Views ---
    function priceYes1e18() external view returns (uint256);

    // --- Quotes ---
    function quoteBuy(Side side, uint256 collateralInUSDC6)
        external view returns (uint256 sharesOutUSDC6, uint256 feeUSDC6, uint256 pYesAfter1e18);

    function quoteSell(Side side, uint256 sharesInUSDC6)
        external view returns (uint256 collateralOutUSDC6, uint256 feeUSDC6, uint256 pYesAfter1e18);

    // --- Trading ---
    function buy(Side side, uint256 collateralInUSDC6, uint256 minSharesOutUSDC6)
        external returns (uint256 sharesOutUSDC6);

    function sell(Side side, uint256 sharesInUSDC6, uint256 minCollateralOutUSDC6)
        external returns (uint256 collateralOutUSDC6);

    // --- Lifecycle ---
    function lock() external;
    function resolve(Result r, bytes32 evidenceHash) external;
    function cancel(bytes32 reasonHash) external;

    // --- Redemption ---
    function redeem(Side side, uint256 sharesInUSDC6) external returns (uint256 collateralOutUSDC6);

    // --- Fees ---
    function sweepFees() external returns (uint256 sweptUSDC6);
}
