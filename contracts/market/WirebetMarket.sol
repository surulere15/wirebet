// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IWirebetMarket.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IPositions.sol";
import "../interfaces/IFeeRouter.sol";
import "./LMSRMath.sol";
import "./MarketErrors.sol";

/**
 * @title WirebetMarket
 * @author JOE
 * @notice The core market engine for a binary prediction market.
 * - Implements the LMSR AMM for pricing.
 * - Integrates with ERC-1155 for position tokens and ERC-4626 for collateral vaulting.
 * - Enforces strict solvency and risk management invariants.
 * - Follows a defined lifecycle from OPEN to RESOLVED.
 */
contract WirebetMarket is IWirebetMarket, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public immutable override marketId;
    IERC20 public immutable override collateral;
    IVault public immutable vault;
    IPositions public immutable positions;
    IFeeRouter public immutable override feeRouter;
    address public immutable override resolver;
    uint64 public immutable override closeTime;

    State public override state;
    Result public override result;
    RiskParams public risk;

    uint256 public qY; // USDC6 share units
    uint256 public qN; // USDC6 share units
    uint256 public b; // USDC6 liquidity parameter

    uint256 public feesAccruedUSDC6;

    constructor(
        bytes32 _marketId,
        address _collateral,
        address _vault,
        address _positions,
        address _feeRouter,
        address _resolver,
        uint64 _closeTime,
        RiskParams memory _risk,
        uint256 _bUSDC6
    ) {
        if (_collateral == address(0) || _vault == address(0) || _positions == address(0) || _feeRouter == address(0) || _resolver == address(0)) {
            revert ZeroAddress();
        }
        marketId = _marketId;
        collateral = IERC20(_collateral);
        vault = IVault(_vault);
        positions = IPositions(_positions);
        feeRouter = IFeeRouter(_feeRouter);
        resolver = _resolver;
        closeTime = _closeTime;
        risk = _risk;
        b = _bUSDC6;
        state = State.OPEN;
        result = Result.UNSET;
    }

    // --- Views ---

    function priceYes1e18() public view override returns (uint256) {
        return LMSRMath.priceYes1e18(qY, qN, b);
    }

    function liabilityUSDC6() public view returns (uint256) {
        return qY >= qN ? qY : qN;
    }

    function requiredReserveUSDC6() public view returns (uint256) {
        uint256 L = liabilityUSDC6();
        uint256 buffer = (L * risk.bufferBps) / 10_000;
        return L + buffer;
    }

    function sweepableUSDC6() public view returns (uint256) {
        uint256 assets = vault.totalAssets();
        uint256 req = requiredReserveUSDC6();
        if (assets <= req) return 0;
        uint256 excess = assets - req;
        return excess < feesAccruedUSDC6 ? excess : feesAccruedUSDC6;
    }

    // --- Quotes ---

    function quoteBuy(Side side, uint256 collateralInUSDC6)
        public
        view
        override
        returns (
            uint256 sharesOutUSDC6,
            uint256 feeUSDC6,
            uint256 pYesAfter1e18
        )
    {
        if (state != State.OPEN) revert NotOpen();
        if (collateralInUSDC6 == 0) revert ZeroAmount();
        if (collateralInUSDC6 > risk.maxTradeSizeUSDC6) revert TooLarge();

        feeUSDC6 = (collateralInUSDC6 * risk.feeBps) / 10_000;
        uint256 net = collateralInUSDC6 - feeUSDC6;
        // Use post-deposit assets for exposure cap (incoming collateral will be deposited)
        uint256 assets = vault.totalAssets() + collateralInUSDC6;
        uint256 hi = _computeHiBoundSharesUSDC6(assets);
        
        sharesOutUSDC6 = _binSearchSharesOutUSDC6(side, net, hi);

        if (side == Side.YES) {
            pYesAfter1e18 = LMSRMath.priceYes1e18(qY + sharesOutUSDC6, qN, b);
        } else {
            pYesAfter1e18 = LMSRMath.priceYes1e18(qY, qN + sharesOutUSDC6, b);
        }
    }

    function quoteSell(Side side, uint256 sharesInUSDC6)
        public
        view
        override
        returns (
            uint256 collateralOutUSDC6,
            uint256 feeUSDC6,
            uint256 pYesAfter1e18
        )
    {
        if (state != State.OPEN) revert NotOpen();
        if (sharesInUSDC6 == 0) revert ZeroAmount();

        uint256 C0 = LMSRMath.costUSDC6(qY, qN, b);
        uint256 C1;

        if (side == Side.YES) {
            if (sharesInUSDC6 > qY) revert InsufficientShares();
            C1 = LMSRMath.costUSDC6(qY - sharesInUSDC6, qN, b);
            pYesAfter1e18 = LMSRMath.priceYes1e18(qY - sharesInUSDC6, qN, b);
        } else {
            if (sharesInUSDC6 > qN) revert InsufficientShares();
            C1 = LMSRMath.costUSDC6(qY, qN - sharesInUSDC6, b);
            pYesAfter1e18 = LMSRMath.priceYes1e18(qY, qN - sharesInUSDC6, b);
        }

        uint256 gross = C0 - C1;
        feeUSDC6 = (gross * risk.feeBps) / 10_000;
        collateralOutUSDC6 = gross - feeUSDC6;
    }

    // --- Trading ---

    function buy(Side side, uint256 collateralInUSDC6, uint256 minSharesOutUSDC6)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 sharesOutUSDC6)
    {
        uint256 fee;
        (sharesOutUSDC6, fee, ) = quoteBuy(side, collateralInUSDC6);
        if (sharesOutUSDC6 == 0) revert ZeroAmount();
        if (sharesOutUSDC6 < minSharesOutUSDC6) revert Slippage();

        // Use post-deposit assets for exposure check (collateral will be deposited)
        uint256 assetsAfter = vault.totalAssets() + collateralInUSDC6;
        uint256 newQY = qY;
        uint256 newQN = qN;
        if (side == Side.YES) newQY += sharesOutUSDC6;
        else newQN += sharesOutUSDC6;
        uint256 newLiab = newQY >= newQN ? newQY : newQN;
        if (newLiab > _exposureCapUSDC6(assetsAfter)) revert ExposureExceeded();

        // Transfer full collateral (including fee) from user to this contract
        collateral.safeTransferFrom(msg.sender, address(this), collateralInUSDC6);
        // Approve vault and deposit so shares are minted to this contract
        collateral.approve(address(vault), collateralInUSDC6);
        vault.deposit(collateralInUSDC6, address(this));
        feesAccruedUSDC6 += fee;

        uint256 id = positions.tokenId(marketId, side == Side.YES ? 0 : 1);
        positions.mint(msg.sender, id, sharesOutUSDC6);

        qY = newQY;
        qN = newQN;

        emit TradeExecuted(msg.sender, side, true, collateralInUSDC6, sharesOutUSDC6, fee);
    }

    function sell(Side side, uint256 sharesInUSDC6, uint256 minCollateralOutUSDC6)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 collateralOutUSDC6)
    {
        uint256 fee;
        (collateralOutUSDC6, fee, ) = quoteSell(side, sharesInUSDC6);
        if (collateralOutUSDC6 < minCollateralOutUSDC6) revert Slippage();

        uint256 id = positions.tokenId(marketId, side == Side.YES ? 0 : 1);
        positions.burn(msg.sender, id, sharesInUSDC6);

        if (side == Side.YES) qY -= sharesInUSDC6;
        else qN -= sharesInUSDC6;

        vault.withdraw(collateralOutUSDC6, msg.sender, address(this));
        feesAccruedUSDC6 += fee;

        emit TradeExecuted(msg.sender, side, false, collateralOutUSDC6, sharesInUSDC6, fee);
    }

    // --- Lifecycle ---

    /**
     * @notice Locks the market after the close time has passed, preventing further trading.
     * @dev This function is intentionally callable by anyone (permissionless). Once the
     *      closeTime has elapsed, any address may call lock() to transition the market from
     *      OPEN to LOCKED. This design ensures markets cannot remain open past their
     *      designated close time, even if the resolver or owner is unresponsive.
     */
    function lock() external override {
        if (state != State.OPEN) revert NotOpen();
        if (block.timestamp < closeTime) revert TooEarly();
        state = State.LOCKED;
        emit StateChanged(State.OPEN, State.LOCKED);
    }

    function resolve(Result r, bytes32 /*evidenceHash*/) external override {
        if (msg.sender != resolver) revert Unauthorized();
        if (state != State.LOCKED) revert NotLocked();
        if (r != Result.YES && r != Result.NO) revert InvalidResult();
        result = r;
        state = State.RESOLVED;
        emit StateChanged(State.LOCKED, State.RESOLVED);
    }
    
    function cancel(bytes32 /*reasonHash*/) external override {
        if (msg.sender != resolver) revert Unauthorized();
        if (state == State.RESOLVED) revert CannotCancelResolved();
        State from = state;
        state = State.CANCELLED;
        result = Result.CANCELLED;
        emit StateChanged(from, State.CANCELLED);
    }

    // --- Redemption ---

    function redeem(Side side, uint256 sharesInUSDC6)
        external
        override
        nonReentrant
        returns (uint256 collateralOutUSDC6)
    {
        if (state != State.RESOLVED && state != State.CANCELLED) revert NotResolved();
        if (sharesInUSDC6 == 0) revert ZeroAmount();

        uint256 id = positions.tokenId(marketId, side == Side.YES ? 0 : 1);
        positions.burn(msg.sender, id, sharesInUSDC6);

        if (state == State.CANCELLED) {
            // Cancelled market: all position holders redeem proportionally.
            // Each share is backed by collateral in the vault; return 1:1.
            collateralOutUSDC6 = sharesInUSDC6;
        } else {
            // Resolved market: only winning side gets collateral.
            bool wins = (result == Result.YES && side == Side.YES)
                || (result == Result.NO && side == Side.NO);
            if (!wins) return 0;
            collateralOutUSDC6 = sharesInUSDC6;
        }

        vault.withdraw(collateralOutUSDC6, msg.sender, address(this));

        emit Redeemed(msg.sender, side, sharesInUSDC6, collateralOutUSDC6);
    }

    // --- Admin ---

    function pause() external {
        if (msg.sender != resolver) revert Unauthorized();
        _pause();
    }

    function unpause() external {
        if (msg.sender != resolver) revert Unauthorized();
        _unpause();
    }

    // --- Fees ---

    function sweepFees() external override nonReentrant returns (uint256 sweptUSDC6) {
        sweptUSDC6 = sweepableUSDC6();
        if (sweptUSDC6 == 0) return 0;

        feesAccruedUSDC6 -= sweptUSDC6;
        vault.withdraw(sweptUSDC6, address(feeRouter), address(this));
        feeRouter.routeTradeFee(marketId, address(collateral), sweptUSDC6);
        
        emit FeesSwept(sweptUSDC6);
    }
    
    // --- Internal routines ---

    function _exposureCapUSDC6(uint256 assets) internal view returns (uint256) {
        return (assets * risk.maxNetExposureBps) / 10_000;
    }

    function _computeHiBoundSharesUSDC6(uint256 assetsUSDC6) internal view returns (uint256 hiUSDC6) {
        uint256 cap = _exposureCapUSDC6(assetsUSDC6);
        uint256 L0 = liabilityUSDC6();
        if (cap <= L0) return 0;
        hiUSDC6 = cap - L0;
    }

    function _binSearchSharesOutUSDC6(Side side, uint256 netUSDC6, uint256 hiUSDC6)
        internal
        view
        returns (uint256 sharesOutUSDC6)
    {
        if (hiUSDC6 == 0 || netUSDC6 == 0) return 0;

        uint256 C0 = LMSRMath.costUSDC6(qY, qN, b);
        uint256 lo = 0;
        uint256 hi = hiUSDC6;

        for (uint256 i = 0; i < 24; i++) {
            uint256 mid = (lo + hi) >> 1;
            if (mid == 0) break;
            uint256 C1;
            if (side == Side.YES) C1 = LMSRMath.costUSDC6(qY + mid, qN, b);
            else C1 = LMSRMath.costUSDC6(qY, qN + mid, b);
            uint256 delta = C1 - C0;
            if (delta > netUSDC6) {
                hi = mid;
            } else {
                lo = mid;
            }
        }
        sharesOutUSDC6 = lo;
    }
}
