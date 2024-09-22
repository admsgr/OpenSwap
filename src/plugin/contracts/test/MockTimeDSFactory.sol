// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import '../base/OperaFeeConfiguration.sol';
import '../libraries/AdaptiveFee.sol';

import './MockTimeOperaBasePluginV1.sol';

import '../interfaces/IBasePluginV1Factory.sol';

import '@openswap/opera-insider-core/contracts/interfaces/plugin/IOperaPluginFactory.sol';

contract MockTimeDSFactory is IBasePluginV1Factory {
  /// @inheritdoc IBasePluginV1Factory
  bytes32 public constant override OPERA_BASE_PLUGIN_FACTORY_ADMINISTRATOR = keccak256('OPERA_BASE_PLUGIN_FACTORY_ADMINISTRATOR');

  address public immutable override operaFactory;

  /// @dev values of constants for sigmoids in fee calculation formula
  OperaFeeConfiguration public override defaultFeeConfiguration;

  /// @inheritdoc IBasePluginV1Factory
  mapping(address => address) public override pluginByPool;

  /// @inheritdoc IBasePluginV1Factory
  address public override farmingAddress;

  constructor(address _operaFactory) {
    operaFactory = _operaFactory;
    defaultFeeConfiguration = AdaptiveFee.initialFeeConfiguration();
  }

  /// @inheritdoc IOperaPluginFactory
  function beforeCreatePoolHook(address pool, address, address, address, address, bytes calldata) external override returns (address) {
    return _createPlugin(pool);
  }

  /// @inheritdoc IOperaPluginFactory
  function afterCreatePoolHook(address, address, address) external view override {
    require(msg.sender == operaFactory);
  }

  function createPluginForExistingPool(address token0, address token1) external override returns (address) {
    IOperaFactory factory = IOperaFactory(operaFactory);
    require(factory.hasRoleOrOwner(factory.POOLS_ADMINISTRATOR_ROLE(), msg.sender));

    address pool = factory.poolByPair(token0, token1);
    require(pool != address(0), 'Pool not exist');

    return _createPlugin(pool);
  }

  function setPluginForPool(address pool, address plugin) external {
    pluginByPool[pool] = plugin;
  }

  function _createPlugin(address pool) internal returns (address) {
    MockTimeOperaBasePluginV1 volatilityOracle = new MockTimeOperaBasePluginV1(pool, operaFactory, address(this));
    volatilityOracle.changeFeeConfiguration(defaultFeeConfiguration);
    pluginByPool[pool] = address(volatilityOracle);
    return address(volatilityOracle);
  }

  /// @inheritdoc IBasePluginV1Factory
  function setDefaultFeeConfiguration(OperaFeeConfiguration calldata newConfig) external override {
    AdaptiveFee.validateFeeConfiguration(newConfig);
    defaultFeeConfiguration = newConfig;
    emit DefaultFeeConfiguration(newConfig);
  }

  /// @inheritdoc IBasePluginV1Factory
  function setFarmingAddress(address newFarmingAddress) external override {
    require(farmingAddress != newFarmingAddress);
    farmingAddress = newFarmingAddress;
    emit FarmingAddress(newFarmingAddress);
  }
}
