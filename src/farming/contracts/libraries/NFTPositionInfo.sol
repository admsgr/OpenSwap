// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';
import '@openswap/opera-insider-core/contracts/interfaces/IOperaPoolDeployer.sol';
import '@openswap/opera-insider-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@openswap/opera-insider-periphery/contracts/libraries/PoolAddress.sol';

/// @notice Encapsulates the logic for getting info about a NFT token ID
library NFTPositionInfo {
  /// @param deployer The address of the Opera Deployer used in computing the pool address
  /// @param nonfungiblePositionManager The address of the nonfungible position manager to query
  /// @param tokenId The unique identifier of an Opera LP token
  /// @return pool The address of the Opera pool
  /// @return tickLower The lower tick of the Opera position
  /// @return tickUpper The upper tick of the Opera position
  /// @return liquidity The amount of liquidity farmd
  function getPositionInfo(
    IOperaPoolDeployer deployer,
    INonfungiblePositionManager nonfungiblePositionManager,
    uint256 tokenId
  ) internal view returns (IOperaPool pool, int24 tickLower, int24 tickUpper, uint128 liquidity) {
    address token0;
    address token1;
    address pluginDeployer;
    (, , token0, token1, pluginDeployer, tickLower, tickUpper, liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);

    pool = IOperaPool(
      PoolAddress.computeAddress(address(deployer), PoolAddress.PoolKey({deployer: pluginDeployer, token0: token0, token1: token1}))
    );
  }
}
