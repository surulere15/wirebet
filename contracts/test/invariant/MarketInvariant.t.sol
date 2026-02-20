// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";

/*//////////////////////////////////////////////////////////////
// MOCKS (MINIMAL)
//////////////////////////////////////////////////////////////*/

contract MockUSDC6 {
    string public name = "Mock USDC";
    string public symbol = "mUSDC";
    uint8 public decimals = 6;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 amt);
    event Approval(address indexed owner, address indexed spender, uint256 amt);

    function mint(address to, uint256 amt) external {
        balanceOf[to] += amt;
        emit Transfer(address(0), to, amt);
    }

    function approve(address spender, uint256 amt) external returns (bool) {
        allowance[msg.sender][spender] = amt;
        emit Approval(msg.sender, spender, amt);
        return true;
    }

    function transfer(address to, uint256 amt) external returns (bool) {
        _transfer(msg.sender, to, amt);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amt
    ) external returns (bool) {
        uint256 a = allowance[from][msg.sender];
        require(a >= amt, "ALLOWANCE");
        allowance[from][msg.sender] = a - amt;
        _transfer(from, to, amt);
        return true;
    }

    function _transfer(address from, address to, uint256 amt) internal {
        require(balanceOf[from] >= amt, "BAL");
        balanceOf[from] -= amt;
        balanceOf[to] += amt;
        emit Transfer(from, to, amt);
    }
}

contract MockVault4626 {
    MockUSDC6 public immutable asset;
    mapping(address => uint256) public shareBalance;
    uint256 public totalShares;

    constructor(address asset_) {
        asset = MockUSDC6(asset_);
    }

    function totalAssets() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares)
    {
        shares = assets;
        shareBalance[receiver] += shares;
        totalShares += shares;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 sharesBurned) {
        sharesBurned = assets;
        require(shareBalance[owner] >= sharesBurned, "SHARES");
        shareBalance[owner] -= sharesBurned;
        totalShares -= sharesBurned;
        require(asset.transfer(receiver, assets), "VAULT_TRANSFER");
    }
}

contract MockPositions1155 {
    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    function tokenId(bytes32 marketId, uint8 sideBit)
        external
        pure
        returns (uint256)
    {
        return (uint256(marketId) << 1) | uint256(sideBit);
    }

    function mint(address to, uint256 id, uint256 amt) external {
        balanceOf[to][id] += amt;
    }

    function burn(address from, uint256 id, uint256 amt) external {
        uint256 b = balanceOf[from][id];
        require(b >= amt, "BURN_BAL");
        balanceOf[from][id] = b - amt;
    }
}

contract MockFeeRouter {
    event Routed(bytes32 indexed marketId, address indexed token, uint256 amount);

    function routeTradeFee(bytes32 marketId, address token, uint256 amount)
        external
    {
        emit Routed(marketId, token, amount);
    }
}

library LMSRMath_TestOnly {
    function costUSDC6(uint256 qY, uint256 qN, uint256 /*b*/)
        internal
        pure
        returns (uint256)
    {
        return qY + qN;
    }

    function priceYes1e18(uint256 qY, uint256 qN, uint256 /*b*/)
        internal
        pure
        returns (uint256)
    {
        uint256 d = qY + qN;
        if (d == 0) return 5e17;
        return (qY * 1e18) / d;
    }
}

contract WirebetMarket_Ref {
    using LMSRMath_TestOnly for uint256;
    enum Side { YES, NO }
    enum State { OPEN, LOCKED, RESOLVED, CANCELLED }
    enum Result { UNSET, YES, NO, CANCELLED }
    struct RiskParams {
        uint16 feeBps;
        uint16 bufferBps;
        uint16 maxNetExposureBps;
        uint256 maxTradeSizeUSDC6;
    }
    bytes32 public immutable marketId;
    MockUSDC6 public immutable collateral;
    MockVault4626 public immutable vault;
    MockPositions1155 public immutable positions;
    MockFeeRouter public immutable feeRouter;
    address public immutable resolver;
    uint64 public immutable closeTime;
    State public state;
    Result public result;
    RiskParams public risk;
    uint256 public qY;
    uint256 public qN;
    uint256 public b;
    uint256 public feesAccruedUSDC6;
    event TradeExecuted(address indexed user, Side indexed side, bool indexed isBuy, uint256 collateralAmount, uint256 sharesAmount, uint256 feePaid);
    event FeesSwept(uint256 amount);
    error NotOpen();
    error TooEarly();
    error TooLarge();
    error Slippage();
    error ExposureExceeded();
    error Unauthorized();
    error ZeroAmount();
    error NotLocked();
    error NotResolved();

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
        marketId = _marketId;
        collateral = MockUSDC6(_collateral);
        vault = MockVault4626(_vault);
        positions = MockPositions1155(_positions);
        feeRouter = MockFeeRouter(_feeRouter);
        resolver = _resolver;
        closeTime = _closeTime;
        risk = _risk;
        b = _bUSDC6;
        state = State.OPEN;
        result = Result.UNSET;
    }

    function priceYes1e18() public view returns (uint256) {
        return LMSRMath_TestOnly.priceYes1e18(qY, qN, b);
    }

    function liabilityUSDC6() public view returns (uint256) {
        return qY >= qN ? qY : qN;
    }

    function requiredReserveUSDC6() public view returns (uint256) {
        uint256 L = liabilityUSDC6();
        uint256 buf = (L * risk.bufferBps) / 10_000;
        return L + buf;
    }

    function sweepableUSDC6() public view returns (uint256) {
        uint256 assets = collateral.balanceOf(address(vault));
        uint256 req = requiredReserveUSDC6();
        if (assets <= req) return 0;
        uint256 excess = assets - req;
        return excess < feesAccruedUSDC6 ? excess : feesAccruedUSDC6;
    }

    function _exposureCapUSDC6(uint256 assets) internal view returns (uint256) {
        return (assets * risk.maxNetExposureBps) / 10_000;
    }

    function quoteBuy(Side side, uint256 collateralInUSDC6)
        public
        view
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
        sharesOutUSDC6 = collateralInUSDC6 - feeUSDC6;
        if (side == Side.YES) {
            pYesAfter1e18 = LMSRMath_TestOnly.priceYes1e18(
                qY + sharesOutUSDC6,
                qN,
                b
            );
        } else {
            pYesAfter1e18 = LMSRMath_TestOnly.priceYes1e18(
                qY,
                qN + sharesOutUSDC6,
                b
            );
        }
    }

    function quoteSell(Side side, uint256 sharesInUSDC6)
        public
        view
        returns (
            uint256 collateralOutUSDC6,
            uint256 feeUSDC6,
            uint256 pYesAfter1e18
        )
    {
        if (state != State.OPEN) revert NotOpen();
        if (sharesInUSDC6 == 0) revert ZeroAmount();
        feeUSDC6 = (sharesInUSDC6 * risk.feeBps) / 10_000;
        collateralOutUSDC6 = sharesInUSDC6 - feeUSDC6;
        if (side == Side.YES) {
            pYesAfter1e18 = LMSRMath_TestOnly.priceYes1e18(
                qY - sharesInUSDC6,
                qN,
                b
            );
        } else {
            pYesAfter1e18 = LMSRMath_TestOnly.priceYes1e18(
                qY,
                qN - sharesInUSDC6,
                b
            );
        }
    }

    function buy(
        Side side,
        uint256 collateralInUSDC6,
        uint256 minSharesOutUSDC6
    ) public returns (uint256 sharesOutUSDC6) {
        uint256 fee;
        (sharesOutUSDC6, fee, ) = quoteBuy(side, collateralInUSDC6);
        if (sharesOutUSDC6 < minSharesOutUSDC6) revert Slippage();

        uint256 assetsBefore = collateral.balanceOf(address(vault));
        uint256 cap = _exposureCapUSDC6(assetsBefore);
        uint256 newQY = qY;
        uint256 newQN = qN;
        if (side == Side.YES) newQY += sharesOutUSDC6;
        else newQN += sharesOutUSDC6;
        uint256 newLiab = newQY >= newQN ? newQY : newQN;
        if (newLiab > cap) revert ExposureExceeded();

        require(
            collateral.transferFrom(msg.sender, address(this), collateralInUSDC6),
            "IN"
        );
        require(
            collateral.transfer(address(vault), collateralInUSDC6 - fee),
            "TO_VAULT"
        );
        vault.deposit(collateralInUSDC6 - fee, address(this));
        feesAccruedUSDC6 += fee;

        uint256 id = positions.tokenId(
            marketId,
            side == Side.YES ? 0 : 1
        );
        positions.mint(msg.sender, id, sharesOutUSDC6);

        qY = newQY;
        qN = newQN;
        emit TradeExecuted(
            msg.sender,
            side,
            true,
            collateralInUSDC6,
            sharesOutUSDC6,
            fee
        );
    }

    function sell(
        Side side,
        uint256 sharesInUSDC6,
        uint256 minCollateralOutUSDC6
    ) public returns (uint256 collateralOutUSDC6) {
        uint256 fee;
        (collateralOutUSDC6, fee, ) = quoteSell(side, sharesInUSDC6);
        if (collateralOutUSDC6 < minCollateralOutUSDC6) revert Slippage();

        uint256 id = positions.tokenId(
            marketId,
            side == Side.YES ? 0 : 1
        );
        positions.burn(msg.sender, id, sharesInUSDC6);

        if (side == Side.YES) qY -= sharesInUSDC6;
        else qN -= sharesInUSDC6;

        vault.withdraw(collateralOutUSDC6, address(this), address(this));
        require(collateral.transfer(msg.sender, collateralOutUSDC6), "OUT");
        feesAccruedUSDC6 += fee;
        emit TradeExecuted(
            msg.sender,
            side,
            false,
            collateralOutUSDC6,
            sharesInUSDC6,
            fee
        );
    }
    
    function lock() external {
        if (state != State.OPEN) revert NotOpen();
        if (block.timestamp < closeTime) revert TooEarly();
        state = State.LOCKED;
    }

    function resolve(Result r, bytes32 /*evidence*/) external {
        if (msg.sender != resolver) revert Unauthorized();
        if (state != State.LOCKED) revert NotLocked();
        require(r == Result.YES || r == Result.NO, "BAD_RES");
        result = r;
        state = State.RESOLVED;
    }

    function redeem(Side side, uint256 sharesInUSDC6)
        public
        returns (uint256 collateralOutUSDC6)
    {
        if (state != State.RESOLVED) revert NotResolved();
        if (sharesInUSDC6 == 0) revert ZeroAmount();
        bool wins = (result == Result.YES && side == Side.YES) ||
            (result == Result.NO && side == Side.NO);
        
        uint256 id = positions.tokenId(marketId, side == Side.YES ? 0 : 1);
        positions.burn(msg.sender, id, sharesInUSDC6);

        if (!wins) return 0;

        collateralOutUSDC6 = sharesInUSDC6;
        vault.withdraw(collateralOutUSDC6, address(this), address(this));
        require(collateral.transfer(msg.sender, collateralOutUSDC6), "REDEEM");
    }

    function sweepFees() external returns (uint256 sweptUSDC6) {
        sweptUSDC6 = sweepableUSDC6();
        if (sweptUSDC6 == 0) return 0;

        vault.withdraw(sweptUSDC6, address(this), address(this));
        require(collateral.transfer(address(feeRouter), sweptUSDC6), "SWEEP");
        feeRouter.routeTradeFee(marketId, address(collateral), sweptUSDC6);
        feesAccruedUSDC6 -= sweptUSDC6;
        emit FeesSwept(sweptUSDC6);
    }
}

contract MarketHandler {
    WirebetMarket_Ref public market;
    MockUSDC6 public usdc;
    MockPositions1155 public positions;
    bytes32 public marketId;
    address[] public actors;

    constructor(
        WirebetMarket_Ref _market,
        MockUSDC6 _usdc,
        MockPositions1155 _positions,
        bytes32 _marketId,
        address[] memory _actors
    ) {
        market = _market;
        usdc = _usdc;
        positions = _positions;
        marketId = _marketId;
        actors = _actors;
    }

    function actBuy(uint256 actorSeed, uint8 sideSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        WirebetMarket_Ref.Side side = sideSeed % 2 == 0
            ? WirebetMarket_Ref.Side.YES
            : WirebetMarket_Ref.Side.NO;

        amount = bound(amount, 1e6, 1_000 * 1e6);

        usdc.mint(actor, amount);
        vm.startPrank(actor);
        usdc.approve(address(market), amount);
        try market.buy(side, amount, 0) {} catch {}
        vm.stopPrank();
    }

    function actSell(uint256 actorSeed, uint8 sideSeed, uint256 amount) external {
        address actor = actors[actorSeed % actors.length];
        WirebetMarket_Ref.Side side = sideSeed % 2 == 0
            ? WirebetMarket_Ref.Side.YES
            : WirebetMarket_Ref.Side.NO;

        uint8 sideBit = side == WirebetMarket_Ref.Side.YES ? 0 : 1;
        uint256 id = positions.tokenId(marketId, sideBit);
        uint256 bal = positions.balanceOf(actor, id);
        if (bal == 0) return;
        amount = bound(amount, 1, bal);

        vm.startPrank(actor);
        try market.sell(side, amount, 0) {} catch {}
        vm.stopPrank();
    }

    function actSweepFees() external {
        try market.sweepFees() {} catch {}
    }

    // Helpers
    function bound(uint256 x, uint256 lo, uint256 hi) internal pure returns (uint256) {
        if (hi <= lo) return lo;
        return lo + (x % (hi - lo + 1));
    }

    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
}

contract MarketInvariant_CompilesNow is StdInvariant, Test {
    MockUSDC6 public usdc;
    MockVault4626 public vault;
    MockPositions1155 public positions;
    MockFeeRouter public feeRouter;
    WirebetMarket_Ref public market;
    MarketHandler public handler;
    bytes32 public marketId;

    function setUp() external {
        usdc = new MockUSDC6();
        vault = new MockVault4626(address(usdc));
        positions = new MockPositions1155();
        feeRouter = new MockFeeRouter();
        marketId = keccak256(abi.encodePacked("wirebet:market:1"));

        usdc.mint(address(vault), 200_000 * 1e6);

        WirebetMarket_Ref.RiskParams memory rp = WirebetMarket_Ref.RiskParams({
            feeBps: 75,
            bufferBps: 300,
            maxNetExposureBps: 7000,
            maxTradeSizeUSDC6: 1_000 * 1e6
        });
        address resolver = makeAddr("resolver");

        market = new WirebetMarket_Ref(
            marketId,
            address(usdc),
            address(vault),
            address(positions),
            address(feeRouter),
            resolver,
            uint64(block.timestamp + 7 days),
            rp,
            50_000 * 1e6 // b = 50k USDC
        );

        address[] memory actors = new address[](5);
        actors[0] = makeAddr("alice");
        actors[1] = makeAddr("bob");
        actors[2] = makeAddr("carol");
        actors[3] = makeAddr("dave");
        actors[4] = makeAddr("erin");

        handler = new MarketHandler(market, usdc, positions, marketId, actors);
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = handler.actBuy.selector;
        selectors[1] = handler.actSell.selector;
        selectors[2] = handler.actSweepFees.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function invariant_price_bounds() external view {
        uint256 p = market.priceYes1e18();
        assertLe(p, 1e18);
    }

    function invariant_reserve_coverage() external view {
        uint256 assets = usdc.balanceOf(address(vault));
        uint256 required = market.requiredReserveUSDC6();
        assertGe(assets, required, "assets < required reserve");
    }

    function invariant_liability_coverage() external view {
        uint256 assets = usdc.balanceOf(address(vault));
        uint256 liab = market.liabilityUSDC6();
        assertGe(assets, liab, "assets < liability");
    }

    function invariant_sweepable_never_exceeds_excess() external view {
        uint256 assets = usdc.balanceOf(address(vault));
        uint256 required = market.requiredReserveUSDC6();
        uint256 sweepable = market.sweepableUSDC6();
        if (assets <= required) {
            assertEq(sweepable, 0);
        } else {
            uint256 excess = assets - required;
            assertLe(sweepable, excess);
        }
    }

    function invariant_quote_monotonic_buy_yes() external view {
        uint256 p0 = market.priceYes1e18();
        (,, uint256 pAfter) = market.quoteBuy(WirebetMarket_Ref.Side.YES, 1e6);
        assertGe(pAfter, p0);
    }

    function invariant_quote_monotonic_buy_no() external view {
        uint256 p0 = market.priceYes1e18();
        (,, uint256 pAfter) = market.quoteBuy(WirebetMarket_Ref.Side.NO, 1e6);
        assertLe(pAfter, p0);
    }
}
