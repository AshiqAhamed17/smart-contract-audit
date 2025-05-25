# SimpleDex Protocol

## Overview

SimpleDex is a basic decentralized exchange (DEX) implementation that allows users to swap between two ERC20 tokens using an Automated Market Maker (AMM) model. The protocol follows the constant product formula (`x * y = k`), which is the same core mechanism used by popular DEXes like Uniswap v2.

## Core Mechanics

### Constant Product Formula

The SimpleDex operates on the fundamental principle that the product of the reserves must remain constant before and after a trade (minus fees):

```
reserveA * reserveB = k
```

When a user swaps tokens, the protocol ensures that this invariant is maintained. For example, if a user adds tokenA to the pool, they receive an amount of tokenB that maintains the constant product.

### Liquidity Provision

Users can provide liquidity to the protocol by depositing both tokenA and tokenB. In return, they receive LP (Liquidity Provider) tokens that represent their share of the pool. These tokens can later be redeemed to withdraw the proportional share of the pool's assets.

- **First Liquidity Provider**: The first LP receives LP tokens equal to the square root of the product of the deposited amounts.
- **Subsequent Providers**: Later LPs receive tokens proportional to their contribution relative to the existing reserves.

### Swapping Mechanism

Users can swap one token for another through two main functions:
- `swapAForB`: Exchange tokenA for tokenB
- `swapBForA`: Exchange tokenB for tokenA

The amount received is calculated using the constant product formula, with a 0.3% fee applied to each swap. This fee remains in the pool, benefiting liquidity providers.

### Price Oracle

The protocol provides simple price oracle functions that return the current exchange rate between the two tokens:
- `getPriceA`: Returns the price of tokenA in terms of tokenB
- `getPriceB`: Returns the price of tokenB in terms of tokenA

## Protocol Architecture

SimpleDex is designed as a single contract that handles all core functionality:

1. **Liquidity Management**:
   - Adding liquidity (`addLiquidity`)
   - Removing liquidity (`removeLiquidity`)

2. **Trading Functions**:
   - Token swaps in both directions
   - Price calculations

3. **Administrative Functions**:
   - Emergency withdrawals
   - Ownership management

## Technical Implementation

The protocol is implemented in Solidity 0.8.x and uses OpenZeppelin's IERC20 interface for token interactions. It's designed to be deployed using the Foundry development framework.

Key technical aspects include:
- No external dependencies beyond the IERC20 interface
- Simple square root implementation using the Babylonian method
- Event emissions for all significant state changes
- Basic slippage protection through minimum output parameters

## Intended Use Cases

SimpleDex is designed for:
1. Token swapping between two specific ERC20 tokens
2. Providing liquidity to earn fees from trades
3. Basic price discovery between the token pair

## Limitations

As a simplified implementation, SimpleDex has several limitations:
1. Supports only a single token pair per contract deployment
2. No flash loan capabilities
3. Limited governance functionality
4. No multi-hop trades
5. No concentrated liquidity features

## Security Considerations

This protocol is intended for educational and auditing practice purposes. It contains intentional vulnerabilities that would make it unsafe for production use without significant modifications and security improvements.

Users should be aware that the contract has not undergone professional security audits and should not be used with real assets on mainnet without thorough review and remediation of all security issues.
