// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import '../interfaces/callback/IOperaSwapCallback.sol';
import '../interfaces/callback/IOperaMintCallback.sol';
import '../interfaces/callback/IOperaFlashCallback.sol';
import '../interfaces/plugin/IOperaDynamicFeePlugin.sol';
import '../interfaces/IOperaPool.sol';
import '../interfaces/IOperaFactory.sol';
import '../interfaces/IOperaPoolDeployer.sol';
import '../interfaces/IERC20Minimal.sol';

import '../libraries/TickManagement.sol';
import '../libraries/SafeTransfer.sol';
import '../libraries/Constants.sol';
import '../libraries/Plugins.sol';

import './common/Timestamp.sol';

/// @title Opera pool base abstract contract
/// @notice Contains state variables, immutables and common internal functions
/// @dev Decoupling into a separate abstract contract simplifies testing
abstract contract OperaPoolBase is IOperaPool, Timestamp {
  using TickManagement for mapping(int24 => TickManagement.Tick);

  /// @notice The struct with important state values of pool
  /// @dev fits into one storage slot
  /// @param price The square root of the current price in Q64.96 format
  /// @param tick The current tick (price(tick) <= current price). May not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick boundary
  /// @param lastFee The current (last known) fee in hundredths of a bip, i.e. 1e-6 (so 100 is 0.01%). May be obsolete if using dynamic fee plugin
  /// @param pluginConfig The current plugin config as bitmap. Each bit is responsible for enabling/disabling the hooks, the last bit turns on/off dynamic fees logic
  /// @param communityFee The community fee represented as a percent of all collected fee in thousandths, i.e. 1e-3 (so 100 is 10%)
  /// @param unlocked  Reentrancy lock flag, true if the pool currently is unlocked, otherwise - false
  struct GlobalState {
    uint160 price;
    int24 tick;
    uint16 lastFee;
    uint8 pluginConfig;
    uint16 communityFee;
    bool unlocked;
  }

  /// @inheritdoc IOperaPoolImmutables
  uint128 public constant override maxLiquidityPerTick = Constants.MAX_LIQUIDITY_PER_TICK;
  /// @inheritdoc IOperaPoolImmutables
  address public immutable override factory;
  /// @inheritdoc IOperaPoolImmutables
  address public immutable override token0;
  /// @inheritdoc IOperaPoolImmutables
  address public immutable override token1;

  // ! IMPORTANT security note: the pool state can be manipulated
  // ! external contracts using this data must prevent read-only reentrancy

  /// @inheritdoc IOperaPoolState
  uint256 public override totalFeeGrowth0Token;
  /// @inheritdoc IOperaPoolState
  uint256 public override totalFeeGrowth1Token;

  /// @inheritdoc IOperaPoolState
  GlobalState public override globalState;

  /// @inheritdoc IOperaPoolState
  mapping(int24 => TickManagement.Tick) public override ticks;

  /// @inheritdoc IOperaPoolState
  uint32 public override communityFeeLastTimestamp;
  /// @dev The amounts of token0 and token1 that will be sent to the vault
  uint104 internal communityFeePending0;
  uint104 internal communityFeePending1;

  /// @dev The Reserved amounts of token0 and token1 that should stablized the pool
  uint256 internal fedReserve0;
  uint256 internal fedReserve1;

  /// @inheritdoc IOperaPoolState
  address public override plugin;

  /// @inheritdoc IOperaPoolState
  address public override communityVault;

  /// @inheritdoc IOperaPoolState
  mapping(int16 => uint256) public override tickTable;

  /// @inheritdoc IOperaPoolState
  int24 public override nextTickGlobal;
  /// @inheritdoc IOperaPoolState
  int24 public override prevTickGlobal;
  /// @inheritdoc IOperaPoolState
  uint128 public override liquidity;
  /// @inheritdoc IOperaPoolState
  int24 public override tickSpacing;
  // shares one slot with TickStructure.tickTreeRoot

  /// @notice Check that the lower and upper ticks do not violate the boundaries of allowed ticks and are specified in the correct order
  modifier onlyValidTicks(int24 bottomTick, int24 topTick) {
    TickManagement.checkTickRangeValidity(bottomTick, topTick);
    _;
  }

  constructor() {
    address _plugin;
    (_plugin, factory, token0, token1) = _getDeployParameters();
    (prevTickGlobal, nextTickGlobal) = (TickMath.MIN_TICK, TickMath.MAX_TICK);
    globalState.unlocked = true;
    if (_plugin != address(0)) {
      _setPlugin(_plugin);
    }
  }

  /// @inheritdoc IOperaPoolState
  /// @dev safe from read-only reentrancy getter function
  function safelyGetStateOfAMM()
    external
    view
    override
    returns (uint160 sqrtPrice, int24 tick, uint16 lastFee, uint8 pluginConfig, uint128 activeLiquidity, int24 nextTick, int24 previousTick)
  {
    sqrtPrice = globalState.price;
    tick = globalState.tick;
    lastFee = globalState.lastFee;
    pluginConfig = globalState.pluginConfig;
    bool unlocked = globalState.unlocked;
    if (!unlocked) revert IOperaPoolErrors.locked();

    activeLiquidity = liquidity;
    nextTick = nextTickGlobal;
    previousTick = prevTickGlobal;
  }

  /// @inheritdoc IOperaPoolState
  function isUnlocked() external view override returns (bool unlocked) {
    return globalState.unlocked;
  }

  /// @inheritdoc IOperaPoolState
  function getCommunityFeePending() external view override returns (uint128, uint128) {
    return (communityFeePending0, communityFeePending1);
  }

  /// @inheritdoc IOperaPoolState
  function fee() external view override returns (uint16 currentFee) {
    currentFee = globalState.lastFee;
    uint8 pluginConfig = globalState.pluginConfig;

    if (Plugins.hasFlag(pluginConfig, Plugins.DYNAMIC_FEE)) return IOperaDynamicFeePlugin(plugin).getCurrentFee();
  }

  /// @dev Gets the parameter values ​​for creating the pool. They are not passed in the constructor to make it easier to use create2 opcode
  /// Can be overridden in tests
  function _getDeployParameters() internal virtual returns (address, address, address, address) {
    return IOperaPoolDeployer(msg.sender).getDeployParameters();
  }

  /// @dev Gets the default settings for pool initialization. Can be overridden in tests
  function _getDefaultConfiguration() internal virtual returns (uint16, int24, uint16) {
    return IOperaFactory(factory).defaultConfigurationForPool();
  }

  // The main external calls that are used by the pool. Can be overridden in tests

  function _balanceToken0() internal view virtual returns (uint256) {
    return IERC20Minimal(token0).balanceOf(address(this));
  }

  function _balanceToken1() internal view virtual returns (uint256) {
    return IERC20Minimal(token1).balanceOf(address(this));
  }

  function _fedReserveToken0() internal view virtual returns (uint256) {
    return fedReserve0;
  }

  function _fedReserveToken1() internal view virtual returns (uint256) {
    return fedReserve1;
  }

  function _transfer(address token, address to, uint256 amount) internal virtual {
    SafeTransfer.safeTransfer(token, to, amount);
  }

  // These 'callback' functions are wrappers over the callbacks that the pool calls on the msg.sender
  // These methods can be overridden in tests

  /// @dev Using function to save bytecode
  function _swapCallback(int256 amount0, int256 amount1, bytes calldata data) internal virtual {
    IOperaSwapCallback(msg.sender).operaSwapCallback(amount0, amount1, data);
  }

  function _mintCallback(uint256 amount0, uint256 amount1, bytes calldata data) internal virtual {
    IOperaMintCallback(msg.sender).operaMintCallback(amount0, amount1, data);
  }

  function _flashCallback(uint256 fee0, uint256 fee1, bytes calldata data) internal virtual {
    IOperaFlashCallback(msg.sender).operaFlashCallback(fee0, fee1, data);
  }

  // This virtual function is implemented in TickStructure and used in Positions
  /// @dev Add or remove a pair of ticks to the corresponding data structure
  function _addOrRemoveTicks(int24 bottomTick, int24 topTick, bool toggleBottom, bool toggleTop, int24 currentTick, bool remove) internal virtual;

  function _setCommunityFee(uint16 _communityFee) internal {
    globalState.communityFee = _communityFee;
    emit CommunityFee(_communityFee);
  }

  function _setCommunityFeeVault(address _communityFeeVault) internal {
    communityVault = _communityFeeVault;
    emit CommunityVault(_communityFeeVault);
  }

  function _setFee(uint16 _fee) internal {
    globalState.lastFee = _fee;
    emit Fee(_fee);
  }

  function _setFedReserves(uint256 _r0, uint256 _r1) internal {
    fedReserve0 = _r0;
    fedReserve1 = _r1;
    emit FedReservesUpdate(_r0, _r1);
  }

  function _setTickSpacing(int24 _tickSpacing) internal {
    tickSpacing = _tickSpacing;
    emit TickSpacing(_tickSpacing);
  }

  function _setPlugin(address _plugin) internal {
    plugin = _plugin;
    emit Plugin(_plugin);
  }

  function _setPluginConfig(uint8 _pluginConfig) internal {
    globalState.pluginConfig = _pluginConfig;
    emit PluginConfig(_pluginConfig);
  }
}
