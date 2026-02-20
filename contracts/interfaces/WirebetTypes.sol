// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library WirebetTypes {
    enum Outcome {
        UNDECIDED, // 0
        YES, // 1
        NO // 2
    }

    enum MarketState {
        OPEN, // trading enabled
        CLOSED, // trading disabled; awaiting resolution
        RESOLVED, // outcome set; redeem enabled
        CANCELLED // refunds enabled
    }

    struct MarketParams {
        // A short identifier; question text stays off-chain (store IPFS hash off-chain)
        bytes32 questionHash; // keccak256(question / metadata)
        uint64 openTime; // optional; if 0, open immediately
        uint64 closeTime; // trading closes at closeTime
        address collateral; // ERC20 collateral token (e.g., USDC)
        uint16 feeBps; // fee in basis points on trades (0..10_000)
        uint256 initialYes; // initial pool balance for YES side (in collateral units)
        uint256 initialNo; // initial pool balance for NO side (in collateral units)
        address creator; // market creator (for provenance)
        address resolver; // who can resolve/cancel (often ResolutionManager)
    }

    struct MarketView {
        address market;
        MarketState state;
        Outcome outcome;
        bytes32 questionHash;
        uint64 openTime;
        uint64 closeTime;
        address collateral;
        uint16 feeBps;
        uint256 poolYes; // collateral backing YES side (implementation-defined)
        uint256 poolNo; // collateral backing NO side
        uint256 totalYesShares;
        uint256 totalNoShares;
    }
}
