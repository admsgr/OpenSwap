// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.20;

import '@openswap/opera-insider-core/contracts/interfaces/IOperaFactory.sol';
import '@openswap/opera-insider-core/contracts/interfaces/callback/IOperaMintCallback.sol';
import '@openswap/opera-insider-core/contracts/libraries/TickMath.sol';

import '../libraries/PoolAddress.sol';
import '../libraries/CallbackValidation.sol';
import '../libraries/LiquidityAmounts.sol';

import '../libraries/PoolInteraction.sol';

import './PeripheryPayments.sol';
import './PeripheryImmutableState.sol';

/// @title Liquidity management functions
/// @notice Internal functions for safely managing liquidity in Opera
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
abstract contract LiquidityManagement is IOperaMintCallback, PeripheryImmutableState, PeripheryPayments {
    using PoolInteraction for IOperaPool;
    struct MintCallbackData {
        PoolAddress.PoolKey poolKey;
        address payer;
    }

    /// @inheritdoc IOperaMintCallback
    function operaMintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external override {
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        CallbackValidation.verifyCallback(poolDeployer, decoded.poolKey);

        if (amount0Owed > 0) pay(decoded.poolKey.token0, decoded.payer, msg.sender, amount0Owed);
        if (amount1Owed > 0) pay(decoded.poolKey.token1, decoded.payer, msg.sender, amount1Owed);
    }

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

    /// @notice Add liquidity to an initialized pool
    function addLiquidity(
        AddLiquidityParams memory params
    )
        internal
        returns (uint128 liquidity, uint128 actualLiquidity, uint256 amount0, uint256 amount1, IOperaPool pool)
    {
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
            deployer: params.deployer,
            token0: params.token0,
            token1: params.token1
        });

        pool = IOperaPool(PoolAddress.computeAddress(poolDeployer, poolKey));

        // compute the liquidity amount
        {
            uint160 sqrtPriceX96 = pool._getSqrtPrice();
            uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
            uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                params.amount0Desired,
                params.amount1Desired
            );
        }

        (amount0, amount1, actualLiquidity) = pool.mint(
            msg.sender,
            params.recipient,
            params.tickLower,
            params.tickUpper,
            liquidity,
            abi.encode(MintCallbackData({poolKey: poolKey, payer: msg.sender}))
        );

        require(amount0 >= params.amount0Min && amount1 >= params.amount1Min, 'Price slippage check');
    }
}
