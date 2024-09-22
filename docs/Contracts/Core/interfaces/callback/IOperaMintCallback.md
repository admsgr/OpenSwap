

# IOperaMintCallback


Callback for [IOperaPoolActions#mint](../pool/IOperaPoolActions.md#mint)

Any contract that calls [IOperaPoolActions#mint](../pool/IOperaPoolActions.md#mint) must implement this interface

*Developer note: Credit to Uniswap Labs under GPL-2.0-or-later license:
https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces*


## Functions
### operaMintCallback

```solidity
function operaMintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes data) external
```
**Selector**: `0x9e9e7b21`

Called to &#x60;msg.sender&#x60; after minting liquidity to a position from [IOperaPool#mint](../IOperaPool.md#mint).

*Developer note: In the implementation you must pay the pool tokens owed for the minted liquidity.
The caller of this method _must_ be checked to be a OperaPool deployed by the canonical OperaFactory.*

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0Owed | uint256 | The amount of token0 due to the pool for the minted liquidity |
| amount1Owed | uint256 | The amount of token1 due to the pool for the minted liquidity |
| data | bytes | Any data passed through by the caller via the [IOperaPoolActions#mint](../pool/IOperaPoolActions.md#mint) call |

