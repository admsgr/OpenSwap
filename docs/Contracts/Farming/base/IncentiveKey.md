# IncentiveKey



```solidity
struct IncentiveKey {
  contract IERC20Minimal rewardToken;
  contract IERC20Minimal bonusRewardToken;
  contract IOperaPool pool;
  uint256 nonce;
}
```

| Name | Description |
| ---- | ----------- |
| rewardToken | The token being distributed as a reward (token0) |
| bonusRewardToken | The bonus token being distributed as a reward (token1) |
| pool | The Opera pool |
| nonce | The nonce of incentive |
