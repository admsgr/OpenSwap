// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import '@openswap/opera-insider-core/contracts/base/common/Timestamp.sol';
import '@openswap/opera-insider-core/contracts/libraries/Plugins.sol';

import '@openswap/opera-insider-core/contracts/interfaces/IOperaFactory.sol';
import '@openswap/opera-insider-core/contracts/interfaces/plugin/IOperaPlugin.sol';
import '@openswap/opera-insider-core/contracts/interfaces/pool/IOperaPoolState.sol';
import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';

import './interfaces/IOperaBasePluginV1.sol';
import './interfaces/IBasePluginV1Factory.sol';
import './interfaces/IOperaVirtualPool.sol';

import './libraries/VolatilityOracle.sol';
import './libraries/AdaptiveFee.sol';
import './types/OperaFeeConfigurationU144.sol';

/// @title Opera Insider 1.1 default plugin
/// @notice This contract stores timepoints and calculates adaptive fee and statistical averages
contract OperaBasePluginV1 is IOperaBasePluginV1, Timestamp, IOperaPlugin {
  using Plugins for uint8;
  using OperaFeeConfigurationU144Lib for OperaFeeConfiguration;

  uint256 internal constant UINT16_MODULO = 65536;
  using VolatilityOracle for VolatilityOracle.Timepoint[UINT16_MODULO];

  /// @dev The role can be granted in OperaFactory
  bytes32 public constant OPERA_BASE_PLUGIN_MANAGER = keccak256('OPERA_BASE_PLUGIN_MANAGER');

  /// @inheritdoc IOperaPlugin
  uint8 public constant override defaultPluginConfig = uint8(Plugins.AFTER_INIT_FLAG | Plugins.BEFORE_SWAP_FLAG | Plugins.DYNAMIC_FEE);

  /// @inheritdoc IFarmingPlugin
  address public immutable override pool;
  address private immutable factory;
  address private immutable pluginFactory;

  /// @inheritdoc IVolatilityOracle
  VolatilityOracle.Timepoint[UINT16_MODULO] public override timepoints;

  /// @inheritdoc IVolatilityOracle
  uint16 public override timepointIndex;

  /// @inheritdoc IVolatilityOracle
  uint32 public override lastTimepointTimestamp;

  /// @inheritdoc IVolatilityOracle
  bool public override isInitialized;

  /// @dev OperaFeeConfiguration struct packed in uint144
  OperaFeeConfigurationU144 private _feeConfig;

  /// @inheritdoc IFarmingPlugin
  address public override incentive;

  /// @dev the address which connected the last incentive. Needed so that he can disconnect it
  address private _lastIncentiveOwner;

  modifier onlyPool() {
    _checkIfFromPool();
    _;
  }

  constructor(address _pool, address _factory, address _pluginFactory) {
    (factory, pool, pluginFactory) = (_factory, _pool, _pluginFactory);
  }

  /// @inheritdoc IDynamicFeeManager
  function feeConfig()
    external
    view
    override
    returns (uint16 alpha1, uint16 alpha2, uint32 beta1, uint32 beta2, uint16 gamma1, uint16 gamma2, uint16 baseFee)
  {
    (alpha1, alpha2) = (_feeConfig.alpha1(), _feeConfig.alpha2());
    (beta1, beta2) = (_feeConfig.beta1(), _feeConfig.beta2());
    (gamma1, gamma2) = (_feeConfig.gamma1(), _feeConfig.gamma2());
    baseFee = _feeConfig.baseFee();
  }

  function _checkIfFromPool() internal view {
    require(msg.sender == pool, 'Only pool can call this');
  }

  function _getPoolState() internal view returns (uint160 price, int24 tick, uint16 fee, uint8 pluginConfig) {
    (price, tick, fee, pluginConfig, , ) = IOperaPoolState(pool).globalState();
  }

  function _getPluginInPool() internal view returns (address plugin) {
    return IOperaPool(pool).plugin();
  }

  /// @inheritdoc IOperaBasePluginV1
  function initialize() external override {
    require(!isInitialized, 'Already initialized');
    require(_getPluginInPool() == address(this), 'Plugin not attached');
    (uint160 price, int24 tick, , ) = _getPoolState();
    require(price != 0, 'Pool is not initialized');

    uint32 time = _blockTimestamp();
    timepoints.initialize(time, tick);
    lastTimepointTimestamp = time;
    isInitialized = true;

    _updatePluginConfigInPool();
  }

  // ###### Volatility and TWAP oracle ######

  /// @inheritdoc IVolatilityOracle
  function getSingleTimepoint(uint32 secondsAgo) external view override returns (int56 tickCumulative, uint88 volatilityCumulative) {
    // `volatilityCumulative` values for timestamps after the last timepoint _should not_ be compared: they may differ due to interpolation errors
    (, int24 tick, , ) = _getPoolState();
    uint16 lastTimepointIndex = timepointIndex;
    uint16 oldestIndex = timepoints.getOldestIndex(lastTimepointIndex);
    VolatilityOracle.Timepoint memory result = timepoints.getSingleTimepoint(_blockTimestamp(), secondsAgo, tick, lastTimepointIndex, oldestIndex);
    (tickCumulative, volatilityCumulative) = (result.tickCumulative, result.volatilityCumulative);
  }

  /// @inheritdoc IVolatilityOracle
  function getTimepoints(
    uint32[] memory secondsAgos
  ) external view override returns (int56[] memory tickCumulatives, uint88[] memory volatilityCumulatives) {
    // `volatilityCumulative` values for timestamps after the last timepoint _should not_ be compared: they may differ due to interpolation errors
    (, int24 tick, , ) = _getPoolState();
    return timepoints.getTimepoints(_blockTimestamp(), secondsAgos, tick, timepointIndex);
  }

  /// @inheritdoc IVolatilityOracle
  function prepayTimepointsStorageSlots(uint16 startIndex, uint16 amount) external override {
    require(!timepoints[startIndex].initialized); // if not initialized, then all subsequent ones too
    require(amount > 0 && type(uint16).max - startIndex >= amount);

    unchecked {
      for (uint256 i = startIndex; i < startIndex + amount; ++i) {
        timepoints[i].blockTimestamp = 1; // will be overwritten
      }
    }
  }

  // ###### Fee manager ######

  /// @inheritdoc IDynamicFeeManager
  function changeFeeConfiguration(OperaFeeConfiguration calldata _config) external override {
    require(msg.sender == pluginFactory || IOperaFactory(factory).hasRoleOrOwner(OPERA_BASE_PLUGIN_MANAGER, msg.sender));
    AdaptiveFee.validateFeeConfiguration(_config);

    _feeConfig = _config.pack(); // pack struct to uint144 and write in storage
    emit FeeConfiguration(_config);
  }

  /// @inheritdoc IOperaDynamicFeePlugin
  function getCurrentFee() external view override returns (uint16 fee) {
    uint16 lastIndex = timepointIndex;
    OperaFeeConfigurationU144 feeConfig_ = _feeConfig;
    if (feeConfig_.alpha1() | feeConfig_.alpha2() == 0) return feeConfig_.baseFee();

    uint16 oldestIndex = timepoints.getOldestIndex(lastIndex);
    (, int24 tick, , ) = _getPoolState();

    uint88 volatilityAverage = timepoints.getAverageVolatility(_blockTimestamp(), tick, lastIndex, oldestIndex);
    return AdaptiveFee.getFee(volatilityAverage, feeConfig_);
  }

  function _getFeeAtLastTimepoint(
    uint16 lastTimepointIndex,
    uint16 oldestTimepointIndex,
    int24 currentTick,
    OperaFeeConfigurationU144 feeConfig_
  ) internal view returns (uint16 fee) {
    if (feeConfig_.alpha1() | feeConfig_.alpha2() == 0) return feeConfig_.baseFee();

    uint88 volatilityAverage = timepoints.getAverageVolatility(_blockTimestamp(), currentTick, lastTimepointIndex, oldestTimepointIndex);
    return AdaptiveFee.getFee(volatilityAverage, feeConfig_);
  }

  // ###### Farming plugin ######

  /// @inheritdoc IFarmingPlugin
  function setIncentive(address newIncentive) external override {
    bool toConnect = newIncentive != address(0);
    bool accessAllowed;
    if (toConnect) {
      accessAllowed = msg.sender == IBasePluginV1Factory(pluginFactory).farmingAddress();
    } else {
      // we allow the one who connected the incentive to disconnect it,
      // even if he no longer has the rights to connect incentives
      if (_lastIncentiveOwner != address(0)) accessAllowed = msg.sender == _lastIncentiveOwner;
      if (!accessAllowed) accessAllowed = msg.sender == IBasePluginV1Factory(pluginFactory).farmingAddress();
    }
    require(accessAllowed, 'Not allowed to set incentive');

    bool isPluginConnected = _getPluginInPool() == address(this);
    if (toConnect) require(isPluginConnected, 'Plugin not attached');

    address currentIncentive = incentive;
    require(currentIncentive != newIncentive, 'Already active');
    if (toConnect) require(currentIncentive == address(0), 'Has active incentive');

    incentive = newIncentive;
    emit Incentive(newIncentive);

    if (toConnect) {
      _lastIncentiveOwner = msg.sender; // write creator of this incentive
    } else {
      _lastIncentiveOwner = address(0);
    }

    if (isPluginConnected) {
      _updatePluginConfigInPool();
    }
  }

  /// @inheritdoc IFarmingPlugin
  function isIncentiveConnected(address targetIncentive) external view override returns (bool) {
    if (incentive != targetIncentive) return false;
    if (_getPluginInPool() != address(this)) return false;
    (, , , uint8 pluginConfig) = _getPoolState();
    if (!pluginConfig.hasFlag(Plugins.AFTER_SWAP_FLAG)) return false;

    return true;
  }

  // ###### HOOKS ######

  function beforeInitialize(address, uint160) external override onlyPool returns (bytes4) {
    _updatePluginConfigInPool();
    return IOperaPlugin.beforeInitialize.selector;
  }

  function afterInitialize(address, uint160, int24 tick) external override onlyPool returns (bytes4) {
    uint32 _timestamp = _blockTimestamp();
    timepoints.initialize(_timestamp, tick);

    lastTimepointTimestamp = _timestamp;
    isInitialized = true;

    IOperaPool(pool).setFee(_feeConfig.baseFee());
    return IOperaPlugin.afterInitialize.selector;
  }

  /// @dev unused
  function beforeModifyPosition(address, address, int24, int24, int128, bytes calldata) external override onlyPool returns (bytes4) {
    _updatePluginConfigInPool(); // should not be called, reset config
    return IOperaPlugin.beforeModifyPosition.selector;
  }

  /// @dev unused
  function afterModifyPosition(address, address, int24, int24, int128, uint256, uint256, bytes calldata) external override onlyPool returns (bytes4) {
    _updatePluginConfigInPool(); // should not be called, reset config
    return IOperaPlugin.afterModifyPosition.selector;
  }

  function beforeSwap(address, address, bool, int256, uint160, bool, bytes calldata) external override onlyPool returns (bytes4) {
    _writeTimepointAndUpdateFee();
    return IOperaPlugin.beforeSwap.selector;
  }

  function afterSwap(address, address, bool zeroToOne, int256, uint160, int256, int256, bytes calldata) external override onlyPool returns (bytes4) {
    address _incentive = incentive;
    if (_incentive != address(0)) {
      (, int24 tick, , ) = _getPoolState();
      IOperaVirtualPool(_incentive).crossTo(tick, zeroToOne);
    } else {
      _updatePluginConfigInPool(); // should not be called, reset config
    }

    return IOperaPlugin.afterSwap.selector;
  }

  /// @dev unused
  function beforeFlash(address, address, uint256, uint256, bytes calldata) external override onlyPool returns (bytes4) {
    _updatePluginConfigInPool(); // should not be called, reset config
    return IOperaPlugin.beforeFlash.selector;
  }

  /// @dev unused
  function afterFlash(address, address, uint256, uint256, uint256, uint256, bytes calldata) external override onlyPool returns (bytes4) {
    _updatePluginConfigInPool(); // should not be called, reset config
    return IOperaPlugin.afterFlash.selector;
  }

  function _updatePluginConfigInPool() internal {
    uint8 newPluginConfig = defaultPluginConfig;
    if (incentive != address(0)) {
      newPluginConfig |= uint8(Plugins.AFTER_SWAP_FLAG);
    }

    (, , , uint8 currentPluginConfig) = _getPoolState();
    if (currentPluginConfig != newPluginConfig) {
      IOperaPool(pool).setPluginConfig(newPluginConfig);
    }
  }

  function _writeTimepointAndUpdateFee() internal {
    // single SLOAD
    uint16 _lastIndex = timepointIndex;
    uint32 _lastTimepointTimestamp = lastTimepointTimestamp;
    OperaFeeConfigurationU144 feeConfig_ = _feeConfig; // struct packed in uint144
    bool _isInitialized = isInitialized;
    require(_isInitialized, 'Not initialized');

    uint32 currentTimestamp = _blockTimestamp();

    if (_lastTimepointTimestamp == currentTimestamp) return;

    (, int24 tick, uint16 fee, ) = _getPoolState();
    (uint16 newLastIndex, uint16 newOldestIndex) = timepoints.write(_lastIndex, currentTimestamp, tick);

    timepointIndex = newLastIndex;
    lastTimepointTimestamp = currentTimestamp;

    uint16 newFee = _getFeeAtLastTimepoint(newLastIndex, newOldestIndex, tick, feeConfig_);
    if (newFee != fee) {
      IOperaPool(pool).setFee(newFee);
    }
  }
}
