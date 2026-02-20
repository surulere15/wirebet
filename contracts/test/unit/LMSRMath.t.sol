// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../market/LMSRMath.sol";

/**
 * @title LMSRMath Unit Tests
 * @author JOE
 * @notice Validates the core functions of the LMSRMath library.
 * - Tests cost function calculations.
 * - Tests price function calculations.
 * - Checks for expected reverts on invalid inputs.
 */
contract LMSRMathTest is Test {

    uint256 constant B_LARGE = 100_000 * 1e6; // $100k liquidity parameter

    function test_CostFunction_Symmetric() public {
        uint256 qY = 50_000 * 1e6;
        uint256 qN = 50_000 * 1e6;
        uint256 cost = LMSRMath.costUSDC6(qY, qN, B_LARGE);
        // For qY=qN, cost is b*ln(2*exp(q/b)).
        // We expect it to be slightly more than max(qY,qN)
        assertTrue(cost > qY);
    }

    function test_CostFunction_Asymmetric() public {
        uint256 qY = 80_000 * 1e6;
        uint256 qN = 20_000 * 1e6;
        uint256 cost = LMSRMath.costUSDC6(qY, qN, B_LARGE);
        assertTrue(cost > qY);
    }

    function test_Price_Symmetric_ShouldBe50Percent() public {
        uint256 qY = 50_000 * 1e6;
        uint256 qN = 50_000 * 1e6;
        uint256 price = LMSRMath.priceYes1e18(qY, qN, B_LARGE);
        // Expect price to be very close to 0.5 * 1e18
        assertApproxEqAbs(price, 0.5e18, 1e12);
    }

    function test_Price_YES_Higher_ShouldBeAbove50() public {
        uint256 qY = 70_000 * 1e6;
        uint256 qN = 30_000 * 1e6;
        uint256 price = LMSRMath.priceYes1e18(qY, qN, B_LARGE);
        assertTrue(price > 0.5e18);
    }

    function test_Price_NO_Higher_ShouldBeBelow50() public {
        uint256 qY = 30_000 * 1e6;
        uint256 qN = 70_000 * 1e6;
        uint256 price = LMSRMath.priceYes1e18(qY, qN, B_LARGE);
        assertTrue(price < 0.5e18);
    }

    function _externalCostCall(uint256 qY, uint256 qN, uint256 b) external pure returns (uint256) {
        return LMSRMath.costUSDC6(qY, qN, b);
    }

    function test_Revert_InvalidB() public {
        vm.expectRevert(LMSRMath.LMSR_InvalidB.selector);
        this._externalCostCall(1, 1, 0);
    }

    function test_Edge_ZeroShares() public {
        uint256 price = LMSRMath.priceYes1e18(0, 0, B_LARGE);
        assertApproxEqAbs(price, 0.5e18, 1e12);

        uint256 cost = LMSRMath.costUSDC6(0, 0, B_LARGE);
        // b*ln(2)
        uint256 expectedCost = 693147180559945300 * B_LARGE / 1e18;
        assertApproxEqAbs(cost, expectedCost, 1e6);
    }
}
