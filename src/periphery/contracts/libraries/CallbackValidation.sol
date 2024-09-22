// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';
import './PoolAddress.sol';

/// @notice Provides validation for callbacks from Opera Pools
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
library CallbackValidation {
    /// @notice Returns the address of a valid Opera Pool
    /// @param poolDeployer The contract address of the Opera pool deployer
    /// @param deployer The custom pool deployer address
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @return pool The Opera pool contract address
    function verifyCallback(
        address poolDeployer,
        address deployer,
        address tokenA,
        address tokenB
    ) internal view returns (IOperaPool pool) {
        return verifyCallback(poolDeployer, PoolAddress.getPoolKey(deployer, tokenA, tokenB));
    }

    /// @notice Returns the address of a valid Opera Pool
    /// @param poolDeployer The contract address of the Opera pool deployer
    /// @param poolKey The identifying key of the Opera pool
    /// @return pool The Opera pool contract address
    function verifyCallback(
        address poolDeployer,
        PoolAddress.PoolKey memory poolKey
    ) internal view returns (IOperaPool pool) {
        pool = IOperaPool(PoolAddress.computeAddress(poolDeployer, poolKey));
        require(msg.sender == address(pool), 'Invalid caller of callback');
    }
}
