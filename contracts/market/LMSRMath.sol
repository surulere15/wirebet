// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/* LMSRMath — Wirebet v1
 * Units:
 * - qY, qN, b are in USDC micro units (1e6)
 * - cost() returns USDC micro units (1e6)
 * - priceYes() returns 1e18 fixed-point probability (0..1e18)
 * Requires PRBMath signed fixed point:
 * - SD59x18 for exp/ln
 */

// Common PRBMath import layout (adjust if your repo differs)
import { SD59x18, sd } from "prb-math/SD59x18.sol";
import { exp, ln } from "prb-math/SD59x18.sol";

library LMSRMath {
    error LMSR_InvalidB();
    error LMSR_Domain(); // thrown if exp/ln domain issues arise (should not with clamps)

    // Conservative clamp for exp stability.
    // exp(±60) is already huge/small; keep it bounded.
    int256 internal constant U_MAX = 60e18;
    int256 internal constant U_MIN = -60e18;

    /// @notice LMSR cost in USDC6 (1e6)
    function costUSDC6(uint256 qY, uint256 qN, uint256 bUSDC6)
        internal
        pure
        returns (uint256 cUSDC6)
    {
        if (bUSDC6 == 0) revert LMSR_InvalidB();

        int256 u = _ratioWad(qY, bUSDC6); // (qY/b) in 1e18
        int256 v = _ratioWad(qN, bUSDC6); // (qN/b) in 1e18

        u = _clamp(u, U_MIN, U_MAX);
        v = _clamp(v, U_MIN, U_MAX);

        int256 lseWad = _logSumExpWad(u, v); // 1e18

        // lseWad should be >= 0 in practice, but keep safe.
        if (lseWad <= 0) return 0;

        // C = b * lse / 1e18
        cUSDC6 = (bUSDC6 * uint256(lseWad)) / 1e18;
    }

    /// @notice YES price in 1e18 (0..1e18)
    function priceYes1e18(uint256 qY, uint256 qN, uint256 bUSDC6)
        internal
        pure
        returns (uint256 pYes)
    {
        if (bUSDC6 == 0) revert LMSR_InvalidB();

        int256 u = _ratioWad(qY, bUSDC6);
        int256 v = _ratioWad(qN, bUSDC6);

        u = _clamp(u, U_MIN, U_MAX);
        v = _clamp(v, U_MIN, U_MAX);

        int256 m = u > v ? u : v;

        // pYES = exp(u-m) / (exp(u-m) + exp(v-m))
        SD59x18 eu = exp(sd(u - m));
        SD59x18 ev = exp(sd(v - m));

        int256 euWad = eu.unwrap(); // 1e18
        int256 evWad = ev.unwrap(); // 1e18

        // denom in 1e18
        int256 denom = euWad + evWad;
        if (denom <= 0) return 5e17;

        // p = eu/denom in 1e18: (euWad * 1e18) / denom
        pYes = uint256((euWad * 1e18) / denom);
        if (pYes > 1e18) pYes = 1e18;
    }

    /// @dev (q/b) as signed WAD
    function _ratioWad(uint256 qUSDC6, uint256 bUSDC6)
        internal
        pure
        returns (int256 wad)
    {
        // q and b are unsigned; ratio is >= 0, but we keep signed type.
        wad = int256((qUSDC6 * 1e18) / bUSDC6);
    }

    /// @dev ln(exp(u)+exp(v)) using stable log-sum-exp; returns signed WAD.
    function _logSumExpWad(int256 uWad, int256 vWad)
        internal
        pure
        returns (int256 lseWad)
    {
        int256 m = uWad > vWad ? uWad : vWad;

        // a,b <= 0
        int256 a = uWad - m;
        int256 b = vWad - m;

        // exp(a), exp(b) in 1e18
        SD59x18 ea = exp(sd(a));
        SD59x18 eb = exp(sd(b));

        int256 sum = ea.unwrap() + eb.unwrap(); // 1e18

        // ln(sum) in 1e18
        SD59x18 lnSum = ln(sd(sum));

        lseWad = m + lnSum.unwrap();
    }

    function _clamp(int256 x, int256 lo, int256 hi)
        internal
        pure
        returns (int256)
    {
        if (x < lo) return lo;
        if (x > hi) return hi;
        return x;
    }
}
