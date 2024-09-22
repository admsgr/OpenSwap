

# LiquidityManagement


Liquidity management functions

Internal functions for safely managing liquidity in Opera

*Developer note: Credit to Uniswap Labs under GPL-2.0-or-later license:
https://github.com/Uniswap/v3-periphery*

**Inherits:** [IOperaMintCallback](../../Core/interfaces/callback/IOperaMintCallback.md) [PeripheryImmutableState](PeripheryImmutableState.md) [PeripheryPayments](PeripheryPayments.md)

## Structs
### MintCallbackData



```solidity
struct MintCallbackData {
  struct PoolAddress.PoolKey poolKey;
  address payer;
}
```

### AddLiquidityParams



```solidity
struct AddLiquidityParams {
  address token0;
  address token1;
  address deployer;
  address recipient;
  int24 tickLower;
  int24 tickUpper;
  uint256 amount0Desired;
  uint256 amount1Desired;
  uint256 amount0Min;
  uint256 amount1Min;
}
```


## Functions
### operaMintCallback

```solidity
function operaMintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes data) external
```
**Selector**: `0x9e9e7b21`

Called to &#x60;msg.sender&#x60; after minting liquidity to a position from [IOperaPool#mint](../../Core/interfaces/IOperaPool.md#mint).

*Developer note: In the implementation you must pay the pool tokens owed for the minted liquidity.
The caller of this method _must_ be checked to be a OperaPool deployed by the canonical OperaFactory.*

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0Owed | uint256 | The amount of token0 due to the pool for the minted liquidity |
| amount1Owed | uint256 | The amount of token1 due to the pool for the minted liquidity |
| data | bytes | Any data passed through by the caller via the [IOperaPoolActions#mint](../../Core/interfaces/pool/IOperaPoolActions.md#mint) call |

