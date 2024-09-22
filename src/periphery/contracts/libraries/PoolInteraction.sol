// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.20;

import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';

import './PositionKey.sol';

/// @title Implements commonly used interactions with Opera pool
library PoolInteraction {
    function _getPositionInPool(
        IOperaPool pool,
        address owner,
        int24 tickLower,
        int24 tickUpper
    )
        internal
        view
        returns (
            uint256 liquidityAmount,
            uint256 innerFeeGrowth0Token,
            uint256 innerFeeGrowth1Token,
            uint128 fees0,
            uint128 fees1
        )
    {
        return pool.positions(PositionKey.compute(owner, tickLower, tickUpper));
    }

    function _getSqrtPrice(IOperaPool pool) internal view returns (uint160 sqrtPriceX96) {
        (sqrtPriceX96, , , , , ) = pool.globalState();
    }

    function _burnPositionInPool(
        IOperaPool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal returns (uint256 amount0, uint256 amount1) {
        return pool.burn(tickLower, tickUpper, liquidity, '0x0');
    }
}
