// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import '@openswap/opera-insider-core/contracts/interfaces/plugin/IOperaPlugin.sol';

contract MockPlugin is IOperaPlugin {
    function defaultPluginConfig() external pure returns (uint8) {
        return 0;
    }

    function beforeInitialize(address, uint160) external pure returns (bytes4) {
        return IOperaPlugin.beforeInitialize.selector;
    }

    function afterInitialize(address, uint160, int24) external pure returns (bytes4) {
        return IOperaPlugin.afterInitialize.selector;
    }

    function beforeModifyPosition(
        address,
        address,
        int24,
        int24,
        int128,
        bytes calldata
    ) external pure returns (bytes4) {
        return IOperaPlugin.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address,
        address,
        int24,
        int24,
        int128,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IOperaPlugin.afterModifyPosition.selector;
    }

    function beforeSwap(address, address, bool, int256, uint160, bool, bytes calldata) external pure returns (bytes4) {
        return IOperaPlugin.beforeSwap.selector;
    }

    function afterSwap(
        address,
        address,
        bool,
        int256,
        uint160,
        int256,
        int256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IOperaPlugin.afterSwap.selector;
    }

    function beforeFlash(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return IOperaPlugin.beforeFlash.selector;
    }

    function afterFlash(
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IOperaPlugin.afterFlash.selector;
    }
}
