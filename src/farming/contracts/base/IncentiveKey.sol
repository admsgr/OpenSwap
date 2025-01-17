// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import '@openswap/opera-insider-core/contracts/interfaces/IERC20Minimal.sol';
import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';

/// @param rewardToken The token being distributed as a reward (token0)
/// @param bonusRewardToken The bonus token being distributed as a reward (token1)
/// @param pool The Opera pool
/// @param nonce The nonce of incentive
struct IncentiveKey {
  IERC20Minimal rewardToken;
  IERC20Minimal bonusRewardToken;
  IOperaPool pool;
  uint256 nonce;
}
