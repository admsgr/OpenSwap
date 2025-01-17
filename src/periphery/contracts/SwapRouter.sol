// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.20;

import '@openswap/opera-insider-core/contracts/libraries/SafeCast.sol';
import '@openswap/opera-insider-core/contracts/libraries/TickMath.sol';
import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';

import './interfaces/ISwapRouter.sol';
import './base/PeripheryImmutableState.sol';
import './base/PeripheryValidation.sol';
import './base/PeripheryPaymentsWithFee.sol';
import './base/Multicall.sol';
import './base/SelfPermit.sol';
import './libraries/Path.sol';
import './libraries/PoolAddress.sol';
import './libraries/CallbackValidation.sol';

/// @title Opera Insider 1.1 Swap Router
/// @notice Router for stateless execution of swaps against Opera
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
contract SwapRouter is
    ISwapRouter,
    PeripheryImmutableState,
    PeripheryValidation,
    PeripheryPaymentsWithFee,
    Multicall,
    SelfPermit
{
    using Path for bytes;
    using SafeCast for uint256;

    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    /// @dev Mapping array the latest time of user swap token
    mapping(address => uint256) private lastSwap;

    constructor(
        address _factory,
        address _WNativeToken,
        address _poolDeployer
    ) PeripheryImmutableState(_factory, _WNativeToken, _poolDeployer) {}

    /// @dev Returns the pool for the given token pair. The pool contract may or may not exist.
    function getPool(address deployer, address tokenA, address tokenB) private view returns (IOperaPool) {
        return IOperaPool(PoolAddress.computeAddress(poolDeployer, PoolAddress.getPoolKey(deployer, tokenA, tokenB)));
    }

    /// @dev Returns the timestamp that show the latest swap of address
    function getLastSwapTimestamp(address _user) external view returns (uint256) {
        return lastSwap[_user];
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    /// @inheritdoc IOperaSwapCallback
    function operaSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external override {
        require(amount0Delta > 0 || amount1Delta > 0, 'Zero liquidity swap'); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address deployer, address tokenOut) = data.path.decodeFirstPool();
        CallbackValidation.verifyCallback(poolDeployer, deployer, tokenIn, tokenOut);

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, data.payer, msg.sender, amountToPay);
        } else {
            // either initiate the next swap or pay
            if (data.path.hasMultiplePools()) {
                data.path = data.path.skipToken();
                exactOutputInternal(amountToPay, msg.sender, 0, data);
            } else {
                amountInCached = amountToPay;
                tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
                pay(tokenIn, data.payer, msg.sender, amountToPay);
            }
        }
    }

    /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 limitSqrtPrice,
        SwapCallbackData memory data
    ) private returns (uint256 amountOut) {
        if (recipient == address(0)) recipient = address(this); // allow swapping to the router address with address 0

        (address tokenIn, address deployer, address tokenOut) = data.path.decodeFirstPool();

        bool zeroToOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = getPool(deployer, tokenIn, tokenOut).swap(
            recipient,
            zeroToOne,
            amountIn.toInt256(),
            limitSqrtPrice == 0
                ? (zeroToOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : limitSqrtPrice,
            abi.encode(data)
        );

        return uint256(-(zeroToOne ? amount1 : amount0));
    }

    /// @inheritdoc ISwapRouter
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable override checkDeadline(params.deadline) returns (uint256 amountOut) {
        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            params.limitSqrtPrice,
            SwapCallbackData({
                path: abi.encodePacked(params.tokenIn, params.deployer, params.tokenOut),
                payer: msg.sender
            })
        );
        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @inheritdoc ISwapRouter
    function exactInput(
        ExactInputParams memory params
    ) external payable override checkDeadline(params.deadline) returns (uint256 amountOut) {
        address payer = msg.sender; // msg.sender pays for the first hop

        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                0,
                SwapCallbackData({
                    path: params.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this); // at this point, the caller has paid
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @inheritdoc ISwapRouter
    function exactInputSingleSupportingFeeOnTransferTokens(
        ExactInputSingleParams calldata params
    ) external payable override checkDeadline(params.deadline) returns (uint256 amountOut) {
        SwapCallbackData memory data = SwapCallbackData({
            path: abi.encodePacked(params.tokenIn, params.deployer, params.tokenOut),
            payer: msg.sender
        });
        address recipient = params.recipient == address(0) ? address(this) : params.recipient;

        bool zeroToOne = params.tokenIn < params.tokenOut;

        (int256 amount0, int256 amount1) = getPool(params.deployer, params.tokenIn, params.tokenOut)
            .swapWithPaymentInAdvance(
                msg.sender,
                recipient,
                zeroToOne,
                params.amountIn.toInt256(),
                params.limitSqrtPrice == 0
                    ? (zeroToOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : params.limitSqrtPrice,
                abi.encode(data)
            );

        amountOut = uint256(-(zeroToOne ? amount1 : amount0));

        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @dev Performs a single exact output swap
    function exactOutputInternal(
        uint256 amountOut,
        address recipient,
        uint160 limitSqrtPrice,
        SwapCallbackData memory data
    ) private returns (uint256 amountIn) {
        if (recipient == address(0)) recipient = address(this); // allow swapping to the router address with address 0

        (address tokenOut, address deployer, address tokenIn) = data.path.decodeFirstPool();

        bool zeroToOne = tokenIn < tokenOut;

        (int256 amount0Delta, int256 amount1Delta) = getPool(deployer, tokenIn, tokenOut).swap(
            recipient,
            zeroToOne,
            -amountOut.toInt256(),
            limitSqrtPrice == 0
                ? (zeroToOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : limitSqrtPrice,
            abi.encode(data)
        );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroToOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (limitSqrtPrice == 0) require(amountOutReceived == amountOut, 'Not received full amountOut');
    }

    /// @inheritdoc ISwapRouter
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable override checkDeadline(params.deadline) returns (uint256 amountIn) {
        // avoid an SLOAD by using the swap return data
        amountIn = exactOutputInternal(
            params.amountOut,
            params.recipient,
            params.limitSqrtPrice,
            SwapCallbackData({
                path: abi.encodePacked(params.tokenOut, params.deployer, params.tokenIn),
                payer: msg.sender
            })
        );

        require(amountIn <= params.amountInMaximum, 'Too much requested');
        amountInCached = DEFAULT_AMOUNT_IN_CACHED; // has to be reset even though we don't use it in the single hop case
    }

    /// @inheritdoc ISwapRouter
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable override checkDeadline(params.deadline) returns (uint256 amountIn) {
        // it's okay that the payer is fixed to msg.sender here, as they're only paying for the "final" exact output
        // swap, which happens first, and subsequent swaps are paid for within nested callback frames

        exactOutputInternal(
            params.amountOut,
            params.recipient,
            0,
            SwapCallbackData({path: params.path, payer: msg.sender})
        );

        amountIn = amountInCached;
        require(amountIn <= params.amountInMaximum, 'Too much requested');
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }
}
