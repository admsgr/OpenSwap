// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.20;

import '@openswap/opera-insider-core/contracts/interfaces/IOperaFactory.sol';
import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';
import './PeripheryImmutableState.sol';
import '../interfaces/IPoolInitializer.sol';

import '../libraries/PoolInteraction.sol';

/// @title Creates and initializes Opera Pools
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
abstract contract PoolInitializer is IPoolInitializer, PeripheryImmutableState {
    using PoolInteraction for IOperaPool;

    /// @inheritdoc IPoolInitializer
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        address deployer,
        uint160 sqrtPriceX96
    ) external payable override returns (address pool) {
        require(token0 < token1, 'Invalid order of tokens');

        IOperaFactory _factory = IOperaFactory(factory);

        if (deployer == address(0)) pool = _factory.poolByPair(token0, token1);
        else {
            pool = _factory.customPoolByPair(deployer, token0, token1);
        }

        if (pool == address(0)) {
            if (deployer == address(0)) {
                pool = _factory.createPool(token0, token1);

                _initializePool(pool, sqrtPriceX96);
            }
        } else {
            uint160 sqrtPriceX96Existing = IOperaPool(pool)._getSqrtPrice();
            if (sqrtPriceX96Existing == 0) {
                _initializePool(pool, sqrtPriceX96);
            }
        }
    }

    function _initializePool(address pool, uint160 initPrice) private {
        IOperaPool(pool).initialize(initPrice);
    }
}
