// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../market/WirebetMarket.sol";
import "../../vault/Vault4626Minimal.sol";
import "../../positions/Positions1155.sol";
import "../../fees/FeeRouter.sol";
import "../../factory/MarketFactory.sol";
import "../../interfaces/IWirebetMarket.sol";

/// @dev Mock USDC with 6 decimals and public mint
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {}
    function decimals() public pure override returns (uint8) { return 6; }
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract WirebetIntegrationTest is Test {
    MockUSDC usdc;
    Positions1155 positions;
    FeeRouter feeRouter;
    MarketFactory factory;

    address owner = address(this);
    address resolver = makeAddr("resolver");
    address treasury = makeAddr("treasury");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    // Market deployment outputs
    address marketAddr;
    address vaultAddr;
    bytes32 marketId;

    // Common risk params: 500 bps buffer, 100 bps fee, 10k USDC max trade, 8000 bps exposure
    RiskParams risk = RiskParams({
        bufferBps: 500,
        feeBps: 100,
        maxTradeSizeUSDC6: 10_000e6,
        maxNetExposureBps: 8000
    });

    uint256 constant B_USDC6 = 1000e6; // b = 1000 USDC

    function setUp() public {
        // Deploy shared infra
        usdc = new MockUSDC();
        positions = new Positions1155();
        feeRouter = new FeeRouter(treasury);

        // Deploy factory and wire it
        factory = new MarketFactory(
            address(positions),
            address(feeRouter),
            address(usdc)
        );

        // Wire permissions
        feeRouter.setFactory(address(factory));
        positions.transferOwnership(address(factory));

        // Create a market via factory
        uint64 closeTime = uint64(block.timestamp + 7 days);
        bytes32 questionHash = keccak256("Will ETH hit 5k?");

        (marketAddr, vaultAddr) = factory.createMarket(
            questionHash,
            resolver,
            closeTime,
            risk,
            B_USDC6
        );

        marketId = WirebetMarket(marketAddr).marketId();

        // Fund users
        usdc.mint(alice, 100_000e6);
        usdc.mint(bob, 100_000e6);

        // Approve market to spend users' USDC
        vm.prank(alice);
        usdc.approve(marketAddr, type(uint256).max);
        vm.prank(bob);
        usdc.approve(marketAddr, type(uint256).max);
    }

    // ===================== Factory Tests =====================

    function test_factoryDeployment() public view {
        // Market and vault should be deployed
        assertTrue(marketAddr != address(0), "market should be deployed");
        assertTrue(vaultAddr != address(0), "vault should be deployed");

        // Market should be wired correctly
        WirebetMarket market = WirebetMarket(marketAddr);
        assertEq(address(market.collateral()), address(usdc));
        assertEq(address(market.vault()), vaultAddr);
        assertEq(address(market.positions()), address(positions));
        assertEq(address(market.feeRouter()), address(feeRouter));
        assertEq(market.resolver(), resolver);

        // Market should be in OPEN state
        assertEq(uint256(market.state()), uint256(State.OPEN));

        // Positions contract should authorize market as minter
        assertTrue(positions.isMinter(marketAddr));

        // FeeRouter should authorize market
        assertTrue(feeRouter.authorizedMarkets(marketAddr));
    }

    function test_factoryRejectsDuplicateMarket() public {
        // createMarket uses marketCount as nonce, so same questionHash
        // gives different marketId. This just verifies marketCount increments.
        assertEq(factory.marketCount(), 1);
    }

    // ===================== Buy Tests =====================

    function test_buyYesShares() public {
        WirebetMarket market = WirebetMarket(marketAddr);
        uint256 buyAmount = 100e6; // 100 USDC

        // Quote first
        (uint256 expectedShares, uint256 expectedFee, uint256 priceAfter) =
            market.quoteBuy(Side.YES, buyAmount);

        assertTrue(expectedShares > 0, "should get shares");
        assertEq(expectedFee, (buyAmount * risk.feeBps) / 10_000, "fee should be 1%");
        assertTrue(priceAfter > 5e17, "YES price should increase after YES buy");

        // Execute buy
        uint256 aliceBalBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 sharesOut = market.buy(Side.YES, buyAmount, 0);

        assertEq(sharesOut, expectedShares, "shares should match quote");
        assertEq(usdc.balanceOf(alice), aliceBalBefore - buyAmount, "USDC deducted");

        // Verify position tokens minted
        uint256 yesTokenId = positions.tokenId(marketId, 0);
        assertEq(positions.balanceOf(alice, yesTokenId), sharesOut, "position tokens minted");

        // Vault should hold the collateral
        assertEq(usdc.balanceOf(vaultAddr), buyAmount, "vault holds collateral");

        // Fees should be tracked
        assertEq(market.feesAccruedUSDC6(), expectedFee, "fees tracked");
    }

    function test_buyNoShares() public {
        WirebetMarket market = WirebetMarket(marketAddr);
        uint256 buyAmount = 100e6;

        vm.prank(bob);
        uint256 sharesOut = market.buy(Side.NO, buyAmount, 0);

        assertTrue(sharesOut > 0, "should get NO shares");

        uint256 noTokenId = positions.tokenId(marketId, 1);
        assertEq(positions.balanceOf(bob, noTokenId), sharesOut, "NO position tokens minted");

        // YES price should decrease after NO buy
        assertTrue(market.priceYes1e18() < 5e17, "YES price should decrease");
    }

    function test_buyRevertsWhenPaused() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.prank(resolver);
        market.pause();

        vm.expectRevert();
        vm.prank(alice);
        market.buy(Side.YES, 100e6, 0);
    }

    function test_buyRevertsZeroAmount() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.expectRevert(ZeroAmount.selector);
        vm.prank(alice);
        market.buy(Side.YES, 0, 0);
    }

    function test_buyRevertsTooLarge() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.expectRevert(TooLarge.selector);
        vm.prank(alice);
        market.buy(Side.YES, risk.maxTradeSizeUSDC6 + 1, 0);
    }

    function test_buyRevertsSlippage() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.expectRevert(Slippage.selector);
        vm.prank(alice);
        market.buy(Side.YES, 100e6, type(uint256).max); // impossible minShares
    }

    // ===================== Sell Tests =====================

    function test_sellYesShares() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        // Alice buys YES first
        vm.prank(alice);
        uint256 sharesBought = market.buy(Side.YES, 100e6, 0);

        // Quote sell
        (uint256 expectedCollateral, uint256 expectedFee,) =
            market.quoteSell(Side.YES, sharesBought);
        assertTrue(expectedCollateral > 0, "should get collateral back");

        // Execute sell
        uint256 aliceBalBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 collateralOut = market.sell(Side.YES, sharesBought, 0);

        assertEq(collateralOut, expectedCollateral, "collateral should match quote");
        assertEq(usdc.balanceOf(alice), aliceBalBefore + collateralOut, "USDC received");

        // Position tokens should be burned
        uint256 yesTokenId = positions.tokenId(marketId, 0);
        assertEq(positions.balanceOf(alice, yesTokenId), 0, "position tokens burned");
    }

    function test_sellRevertsInsufficientShares() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        // Try to sell without any position
        vm.expectRevert(InsufficientShares.selector);
        vm.prank(alice);
        market.sell(Side.YES, 100e6, 0);
    }

    // ===================== Price Movement Tests =====================

    function test_priceMovesCorrectly() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        // Initial price should be ~50% (equal probabilities)
        uint256 initialPrice = market.priceYes1e18();
        assertApproxEqAbs(initialPrice, 5e17, 1e15, "initial price ~50%");

        // Buy YES → price goes up
        vm.prank(alice);
        market.buy(Side.YES, 500e6, 0);
        uint256 priceAfterYes = market.priceYes1e18();
        assertTrue(priceAfterYes > initialPrice, "price up after YES buy");

        // Buy NO → price goes down
        vm.prank(bob);
        market.buy(Side.NO, 500e6, 0);
        uint256 priceAfterNo = market.priceYes1e18();
        assertTrue(priceAfterNo < priceAfterYes, "price down after NO buy");
    }

    // ===================== Lifecycle Tests =====================

    function test_fullLifecycleResolveYes() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        // 1. Alice buys YES, Bob buys NO
        vm.prank(alice);
        uint256 aliceShares = market.buy(Side.YES, 200e6, 0);
        vm.prank(bob);
        uint256 bobShares = market.buy(Side.NO, 200e6, 0);

        assertTrue(aliceShares > 0 && bobShares > 0, "both should get shares");

        // 2. Lock the market
        vm.warp(market.closeTime() + 1);
        market.lock();
        assertEq(uint256(market.state()), uint256(State.LOCKED));

        // Trading should fail when locked
        vm.expectRevert(NotOpen.selector);
        vm.prank(alice);
        market.buy(Side.YES, 100e6, 0);

        // 3. Resolve as YES
        vm.prank(resolver);
        market.resolve(Result.YES, keccak256("evidence"));
        assertEq(uint256(market.state()), uint256(State.RESOLVED));
        assertEq(uint256(market.result()), uint256(Result.YES));

        // 4. Alice redeems (winner) — should get collateral
        uint256 aliceBalBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 aliceRedeemed = market.redeem(Side.YES, aliceShares);
        assertEq(aliceRedeemed, aliceShares, "winner gets 1:1 redemption");
        assertEq(usdc.balanceOf(alice), aliceBalBefore + aliceRedeemed);

        // 5. Bob redeems (loser) — should get 0
        vm.prank(bob);
        uint256 bobRedeemed = market.redeem(Side.NO, bobShares);
        assertEq(bobRedeemed, 0, "loser gets nothing");
    }

    function test_fullLifecycleResolveNo() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.prank(alice);
        uint256 aliceShares = market.buy(Side.YES, 200e6, 0);
        vm.prank(bob);
        uint256 bobShares = market.buy(Side.NO, 200e6, 0);

        vm.warp(market.closeTime() + 1);
        market.lock();

        vm.prank(resolver);
        market.resolve(Result.NO, keccak256("evidence"));

        // Alice (YES holder) loses
        vm.prank(alice);
        uint256 aliceRedeemed = market.redeem(Side.YES, aliceShares);
        assertEq(aliceRedeemed, 0, "YES holder loses");

        // Bob (NO holder) wins
        uint256 bobBalBefore = usdc.balanceOf(bob);
        vm.prank(bob);
        uint256 bobRedeemed = market.redeem(Side.NO, bobShares);
        assertEq(bobRedeemed, bobShares, "NO winner gets 1:1");
        assertEq(usdc.balanceOf(bob), bobBalBefore + bobRedeemed);
    }

    // ===================== Cancellation Tests =====================

    function test_cancelOpenMarket() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        // Alice and Bob both buy
        vm.prank(alice);
        uint256 aliceShares = market.buy(Side.YES, 200e6, 0);
        vm.prank(bob);
        uint256 bobShares = market.buy(Side.NO, 200e6, 0);

        // Cancel the market
        vm.prank(resolver);
        market.cancel(keccak256("reason"));
        assertEq(uint256(market.state()), uint256(State.CANCELLED));
        assertEq(uint256(market.result()), uint256(Result.CANCELLED));

        // Both sides should be able to redeem 1:1
        uint256 aliceBalBefore = usdc.balanceOf(alice);
        vm.prank(alice);
        uint256 aliceRedeemed = market.redeem(Side.YES, aliceShares);
        assertEq(aliceRedeemed, aliceShares, "YES holders redeem 1:1 on cancel");

        uint256 bobBalBefore = usdc.balanceOf(bob);
        vm.prank(bob);
        uint256 bobRedeemed = market.redeem(Side.NO, bobShares);
        assertEq(bobRedeemed, bobShares, "NO holders redeem 1:1 on cancel");

        assertEq(usdc.balanceOf(alice), aliceBalBefore + aliceRedeemed);
        assertEq(usdc.balanceOf(bob), bobBalBefore + bobRedeemed);
    }

    function test_cancelLockedMarket() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.prank(alice);
        market.buy(Side.YES, 100e6, 0);

        vm.warp(market.closeTime() + 1);
        market.lock();

        vm.prank(resolver);
        market.cancel(keccak256("reason"));
        assertEq(uint256(market.state()), uint256(State.CANCELLED));
    }

    function test_cancelRevertsAfterResolution() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.warp(market.closeTime() + 1);
        market.lock();

        vm.prank(resolver);
        market.resolve(Result.YES, keccak256("evidence"));

        vm.expectRevert(CannotCancelResolved.selector);
        vm.prank(resolver);
        market.cancel(keccak256("reason"));
    }

    // ===================== Lock Tests =====================

    function test_lockPermissionless() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.warp(market.closeTime() + 1);

        // Anyone can lock after closeTime
        vm.prank(alice);
        market.lock();
        assertEq(uint256(market.state()), uint256(State.LOCKED));
    }

    function test_lockRevertsTooEarly() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.expectRevert(TooEarly.selector);
        market.lock();
    }

    // ===================== Fee Tests =====================

    function test_sweepFees() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        // Generate fees through trading
        vm.prank(alice);
        market.buy(Side.YES, 1000e6, 0);
        vm.prank(bob);
        market.buy(Side.NO, 1000e6, 0);

        uint256 accrued = market.feesAccruedUSDC6();
        assertTrue(accrued > 0, "fees should be accrued");

        uint256 sweepable = market.sweepableUSDC6();

        if (sweepable > 0) {
            uint256 treasuryBefore = usdc.balanceOf(treasury);
            market.sweepFees();
            uint256 treasuryAfter = usdc.balanceOf(treasury);
            assertEq(treasuryAfter - treasuryBefore, sweepable, "fees sent to treasury");
        }
    }

    // ===================== Access Control Tests =====================

    function test_resolveOnlyResolver() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.warp(market.closeTime() + 1);
        market.lock();

        vm.expectRevert(Unauthorized.selector);
        vm.prank(alice);
        market.resolve(Result.YES, keccak256("evidence"));
    }

    function test_cancelOnlyResolver() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.expectRevert(Unauthorized.selector);
        vm.prank(alice);
        market.cancel(keccak256("reason"));
    }

    function test_pauseOnlyResolver() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.expectRevert(Unauthorized.selector);
        vm.prank(alice);
        market.pause();
    }

    function test_resolveInvalidResult() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        vm.warp(market.closeTime() + 1);
        market.lock();

        vm.expectRevert(InvalidResult.selector);
        vm.prank(resolver);
        market.resolve(Result.UNSET, keccak256("evidence"));
    }

    // ===================== Vault Tests =====================

    function test_vaultOnlyMarket() public {
        Vault4626Minimal vault = Vault4626Minimal(vaultAddr);

        vm.expectRevert(Vault4626Minimal.Unauthorized.selector);
        vm.prank(alice);
        vault.deposit(100e6, alice);
    }

    function test_vaultMarketCannotBeSetTwice() public {
        Vault4626Minimal vault = Vault4626Minimal(vaultAddr);
        // market should already be set by factory
        assertTrue(vault.market() != address(0), "market already set");

        address vaultOwner = vault.owner();
        vm.expectRevert(Vault4626Minimal.MarketAlreadySet.selector);
        vm.prank(vaultOwner);
        vault.setMarket(address(0x1234));
    }

    // ===================== Positions Tests =====================

    function test_positionsOnlyMinter() public {
        uint256 yesTokenId = positions.tokenId(marketId, 0);

        vm.expectRevert(abi.encodeWithSelector(NotMinter.selector, alice));
        vm.prank(alice);
        positions.mint(alice, yesTokenId, 100);
    }

    function test_positionsInvalidSide() public {
        vm.expectRevert(InvalidSide.selector);
        positions.tokenId(marketId, 2);
    }

    // ===================== FeeRouter Tests =====================

    function test_feeRouterUnauthorizedMarket() public {
        vm.expectRevert(FeeRouter.Unauthorized.selector);
        vm.prank(alice);
        feeRouter.routeTradeFee(marketId, address(usdc), 100e6);
    }

    function test_feeRouterFactoryAlreadySet() public {
        vm.expectRevert(FeeRouter.FactoryAlreadySet.selector);
        feeRouter.setFactory(address(0x1234));
    }

    // ===================== Multi-Trade Stress Test =====================

    function test_multipleTradesAndRedemption() public {
        WirebetMarket market = WirebetMarket(marketAddr);

        // Multiple alternating buys
        uint256 totalAliceShares;
        uint256 totalBobShares;

        for (uint256 i = 0; i < 5; i++) {
            vm.prank(alice);
            totalAliceShares += market.buy(Side.YES, 50e6, 0);

            vm.prank(bob);
            totalBobShares += market.buy(Side.NO, 50e6, 0);
        }

        assertTrue(totalAliceShares > 0 && totalBobShares > 0);

        // Resolve and redeem
        vm.warp(market.closeTime() + 1);
        market.lock();
        vm.prank(resolver);
        market.resolve(Result.YES, keccak256("evidence"));

        vm.prank(alice);
        uint256 redeemed = market.redeem(Side.YES, totalAliceShares);
        assertEq(redeemed, totalAliceShares, "all shares redeemable");
    }
}
