// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
pragma abicoder v1;

import '../interfaces/plugin/IOperaPluginFactory.sol';
import './MockPoolPlugin.sol';

// used for testing time dependent behavior
contract MockDefaultPluginFactory is IOperaPluginFactory {
  mapping(address => address) public pluginsForPools;

  function afterCreatePoolHook(address plugin, address pool, address deployer) external override {}

  function beforeCreatePoolHook(address pool, address, address, address, address, bytes calldata) external override returns (address plugin) {
    plugin = address(new MockPoolPlugin(pool));
    pluginsForPools[pool] = plugin;
  }
}
