// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import '@openswap/opera-insider-core/contracts/base/common/Timestamp.sol';
import '@openswap/opera-insider-core/contracts/libraries/Plugins.sol';

import '@openswap/opera-insider-core/contracts/interfaces/IOperaFactory.sol';
import '@openswap/opera-insider-core/contracts/interfaces/plugin/IOperaPlugin.sol';
import '@openswap/opera-insider-core/contracts/interfaces/pool/IOperaPoolState.sol';
import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';

contract CustomPlugin is Timestamp, IOperaPlugin {
    using Plugins for uint8;

    address public pool;
    bytes32 public constant OPERA_BASE_PLUGIN_MANAGER = keccak256('OPERA_BASE_PLUGIN_MANAGER');

    function _getPoolState() internal view returns (uint160 price, int24 tick, uint16 fee, uint8 pluginConfig) {
        (price, tick, fee, pluginConfig, , ) = IOperaPoolState(pool).globalState();
    }

    /// @inheritdoc IOperaPlugin
    uint8 public constant override defaultPluginConfig =
        uint8(Plugins.BEFORE_SWAP_FLAG | Plugins.AFTER_SWAP_FLAG | Plugins.DYNAMIC_FEE);

    function beforeInitialize(address, uint160) external override returns (bytes4) {
        pool = msg.sender;
        _updatePluginConfigInPool();
        return IOperaPlugin.beforeInitialize.selector;
    }

    function afterInitialize(address, uint160, int24) external override returns (bytes4) {
        _updatePluginConfigInPool();
        return IOperaPlugin.afterInitialize.selector;
    }

    /// @dev unused
    function beforeModifyPosition(
        address,
        address,
        int24,
        int24,
        int128,
        bytes calldata
    ) external override returns (bytes4) {
        _updatePluginConfigInPool(); // should not be called, reset config
        return IOperaPlugin.beforeModifyPosition.selector;
    }

    /// @dev unused
    function afterModifyPosition(
        address,
        address,
        int24,
        int24,
        int128,
        uint256,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        _updatePluginConfigInPool(); // should not be called, reset config
        return IOperaPlugin.afterModifyPosition.selector;
    }

    function beforeSwap(
        address,
        address,
        bool,
        int256,
        uint160,
        bool,
        bytes calldata
    ) external override returns (bytes4) {
        IOperaPool(pool).setFee(10000);
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
    ) external override returns (bytes4) {
        IOperaPool(pool).setFee(100);
        return IOperaPlugin.afterSwap.selector;
    }

    /// @dev unused
    function beforeFlash(address, address, uint256, uint256, bytes calldata) external override returns (bytes4) {
        _updatePluginConfigInPool(); // should not be called, reset config
        return IOperaPlugin.beforeFlash.selector;
    }

    /// @dev unused
    function afterFlash(
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        _updatePluginConfigInPool(); // should not be called, reset config
        return IOperaPlugin.afterFlash.selector;
    }

    function _updatePluginConfigInPool() internal {
        uint8 newPluginConfig = defaultPluginConfig;

        (, , , uint8 currentPluginConfig) = _getPoolState();
        if (currentPluginConfig != newPluginConfig) {
            IOperaPool(pool).setPluginConfig(newPluginConfig);
        }
    }
}
