# Wirebet

Community-owned Web3 betting protocol on Base.

## Architecture

- **MarketFactory** — CREATE2 clone factory for deploying market + vault pairs
- **WirebetMarket** — Binary prediction market with LMSR pricing
- **LMSRMath** — Logarithmic Market Scoring Rule math library
- **Vault4626Minimal** — ERC-4626 vault for market collateral
- **Positions1155** — ERC-1155 position tokens (YES/NO shares)
- **FeeRouter** — Fee collection and distribution

## Stack

- **Chain**: Base (Coinbase L2)
- **Language**: Solidity 0.8.24
- **Framework**: Foundry
- **Collateral**: USDC

## Project Structure

```
contracts/
  factory/        MarketFactory.sol
  market/         WirebetMarket.sol, LMSRMath.sol
  vault/          Vault4626Minimal.sol
  positions/      Positions1155.sol
  fees/           FeeRouter.sol
  interfaces/     All interfaces and shared types
  test/           Unit and invariant tests
script/           Foundry deployment scripts
docs/
  strategy/       Strategic plans and execution docs
  outreach/       Domain sale outreach materials
  prospectus/     Investor/acquirer prospectus docs
```

## Development

```bash
# Build
forge build

# Test
forge test

# Deploy (Base Sepolia)
forge script script/DeployBase.s.sol --rpc-url base-sepolia --broadcast
```

## Status

This project is an **MVP in active development** on **Base Sepolia testnet**. Core contracts (MarketFactory, WirebetMarket, LMSR pricing, ERC-4626 vault, ERC-1155 positions) are deployed and functional on testnet. The protocol is not yet live on mainnet.

## Security

**The smart contracts in this repository have not been audited.** Do not use them in production or with real funds until a formal security audit has been completed. If you discover a vulnerability, please report it responsibly to team@wirebet.com.

## License

MIT
