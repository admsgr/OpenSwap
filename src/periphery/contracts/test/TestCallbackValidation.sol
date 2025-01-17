// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import '../libraries/CallbackValidation.sol';

contract TestCallbackValidation {
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        address deployer
    ) external view returns (IOperaPool pool) {
        return CallbackValidation.verifyCallback(factory, tokenA, tokenB, deployer);
    }
}
