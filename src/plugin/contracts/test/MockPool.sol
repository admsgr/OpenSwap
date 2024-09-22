// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;
pragma abicoder v1;

import '@openswap/opera-insider-core/contracts/libraries/TickManagement.sol';
import '@openswap/opera-insider-core/contracts/libraries/Constants.sol';
import '@openswap/opera-insider-core/contracts/libraries/Plugins.sol';
import '@openswap/opera-insider-core/contracts/libraries/TickMath.sol';

import '@openswap/opera-insider-core/contracts/interfaces/pool/IOperaPoolActions.sol';
import '@openswap/opera-insider-core/contracts/interfaces/pool/IOperaPoolState.sol';
import '@openswap/opera-insider-core/contracts/interfaces/pool/IOperaPoolPermissionedActions.sol';
import '@openswap/opera-insider-core/contracts/interfaces/pool/IOperaPoolErrors.sol';
import '@openswap/opera-insider-core/contracts/interfaces/plugin/IOperaPlugin.sol';

/// @title Mock of Opera concentrated liquidity pool for plugins testing
contract MockPool is IOperaPoolActions, IOperaPoolPermissionedActions, IOperaPoolState {
  struct GlobalState {
    uint160 price; // The square root of the current price in Q64.96 format
    int24 tick; // The current tick
    uint16 fee; // The current fee in hundredths of a bip, i.e. 1e-6
    uint8 pluginConfig;
    uint16 communityFee; // The community fee represented as a percent of all collected fee in thousandths (1e-3)
    bool unlocked; // True if the contract is unlocked, otherwise - false
  }

  /// @inheritdoc IOperaPoolState
  uint256 public override totalFeeGrowth0Token;
  /// @inheritdoc IOperaPoolState
  uint256 public override totalFeeGrowth1Token;
  /// @inheritdoc IOperaPoolState
  GlobalState public override globalState;

  /// @inheritdoc IOperaPoolState
  int24 public override nextTickGlobal;
  /// @inheritdoc IOperaPoolState
  int24 public override prevTickGlobal;

  /// @inheritdoc IOperaPoolState
  uint128 public override liquidity;
  /// @inheritdoc IOperaPoolState
  int24 public override tickSpacing;
  /// @inheritdoc IOperaPoolState
  uint32 public override communityFeeLastTimestamp;

  /// @inheritdoc IOperaPoolState
  uint32 public override tickTreeRoot; // The root bitmap of search tree
  /// @inheritdoc IOperaPoolState
  mapping(int16 => uint256) public override tickTreeSecondLayer; // The second layer of search tree

  /// @inheritdoc IOperaPoolState
  address public override plugin;

  address public override communityVault;

  /// @inheritdoc IOperaPoolState
  mapping(int24 => TickManagement.Tick) public override ticks;

  /// @inheritdoc IOperaPoolState
  mapping(int16 => uint256) public override tickTable;

  struct Position {
    uint256 liquidity; // The amount of liquidity concentrated in the range
    uint256 innerFeeGrowth0Token; // The last updated fee growth per unit of liquidity
    uint256 innerFeeGrowth1Token;
    uint128 fees0; // The amount of token0 owed to a LP
    uint128 fees1; // The amount of token1 owed to a LP
  }

  /// @inheritdoc IOperaPoolState
  mapping(bytes32 => Position) public override positions;

  struct InternalState {
    uint256 reserve0;
    uint256 reserve1;
  }

  InternalState public internalState;

  address owner;

  /// @inheritdoc IOperaPoolState
  function getCommunityFeePending() external pure override returns (uint128, uint128) {
    revert('not implemented');
  }

  /// @inheritdoc IOperaPoolState
  function fee() external pure returns (uint16) {
    revert('not implemented');
  }

  /// @inheritdoc IOperaPoolState
  function safelyGetStateOfAMM() external pure override returns (uint160, int24, uint16, uint8, uint128, int24, int24) {
    revert('not implemented');
  }

  constructor() {
    globalState.fee = Constants.INIT_DEFAULT_FEE;
    globalState.unlocked = true;
    owner = msg.sender;
  }

  /// @inheritdoc IOperaPoolState
  function getReserves() external pure override returns (uint128, uint128) {
    revert('not implemented');
  }

  /// @inheritdoc IOperaPoolState
  function isUnlocked() external view override returns (bool unlocked) {
    return globalState.unlocked;
  }

  /// @inheritdoc IOperaPoolActions
  function initialize(uint160 initialPrice) external override {
    int24 tick = TickMath.getTickAtSqrtRatio(initialPrice); // getTickAtSqrtRatio checks validity of initialPrice inside

    if (plugin != address(0)) {
      IOperaPlugin(plugin).beforeInitialize(msg.sender, initialPrice);
    }

    tickSpacing = 60;

    uint8 pluginConfig = globalState.pluginConfig;

    globalState.price = initialPrice;
    globalState.tick = tick;

    if (pluginConfig & Plugins.AFTER_INIT_FLAG != 0) {
      IOperaPlugin(plugin).afterInitialize(msg.sender, initialPrice, tick);
    }
  }

  /// @inheritdoc IOperaPoolActions
  function mint(
    address,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 liquidityDesired,
    bytes calldata data
  ) external override returns (uint256, uint256, uint128) {
    if (globalState.pluginConfig & Plugins.BEFORE_POSITION_MODIFY_FLAG != 0) {
      IOperaPlugin(plugin).beforeModifyPosition(msg.sender, recipient, bottomTick, topTick, int128(liquidityDesired), data);
    }

    if (globalState.pluginConfig & Plugins.AFTER_POSITION_MODIFY_FLAG != 0) {
      IOperaPlugin(plugin).afterModifyPosition(msg.sender, recipient, bottomTick, topTick, int128(liquidityDesired), 0, 0, data);
    }
    return (0, 0, 0);
  }

  /// @inheritdoc IOperaPoolActions
  function burn(int24 bottomTick, int24 topTick, uint128 liquidityDesired, bytes calldata data) external override returns (uint256, uint256) {
    if (globalState.pluginConfig & Plugins.BEFORE_POSITION_MODIFY_FLAG != 0) {
      IOperaPlugin(plugin).beforeModifyPosition(msg.sender, msg.sender, bottomTick, topTick, -int128(liquidityDesired), data);
    }

    if (globalState.pluginConfig & Plugins.AFTER_POSITION_MODIFY_FLAG != 0) {
      IOperaPlugin(plugin).afterModifyPosition(msg.sender, msg.sender, bottomTick, topTick, -int128(liquidityDesired), 0, 0, data);
    }
    return (0, 0);
  }

  /// @inheritdoc IOperaPoolActions
  function collect(address, int24, int24, uint128, uint128) external pure override returns (uint128, uint128) {
    revert('Not implemented');
  }

  /// @inheritdoc IOperaPoolActions
  function swap(address, bool, int256, uint160, bytes calldata) external pure override returns (int256, int256) {
    revert('Not implemented');
  }

  function swapToTick(int24 targetTick) external {
    IOperaPlugin _plugin = IOperaPlugin(plugin);
    if (globalState.pluginConfig & Plugins.BEFORE_SWAP_FLAG != 0) {
      _plugin.beforeSwap(msg.sender, msg.sender, true, 0, 0, false, '');
    }

    globalState.price = TickMath.getSqrtRatioAtTick(targetTick);
    globalState.tick = targetTick;

    if (globalState.pluginConfig & Plugins.AFTER_SWAP_FLAG != 0) {
      _plugin.afterSwap(msg.sender, msg.sender, true, 0, 0, 0, 0, '');
    }
  }

  /// @inheritdoc IOperaPoolActions
  function swapWithPaymentInAdvance(address, address, bool, int256, uint160, bytes calldata) external pure override returns (int256, int256) {
    revert('Not implemented');
  }

  /// @inheritdoc IOperaPoolActions
  function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external override {
    uint8 pluginConfig = globalState.pluginConfig;
    if (pluginConfig & Plugins.BEFORE_FLASH_FLAG != 0) {
      IOperaPlugin(plugin).beforeFlash(msg.sender, recipient, amount0, amount1, data);
    }

    if (pluginConfig & Plugins.AFTER_FLASH_FLAG != 0) {
      IOperaPlugin(plugin).afterFlash(msg.sender, recipient, amount0, amount1, 0, 0, data);
    }
  }

  /// @inheritdoc IOperaPoolPermissionedActions
  function setCommunityFee(uint16 newCommunityFee) external override {
    if (newCommunityFee > Constants.MAX_COMMUNITY_FEE || newCommunityFee == globalState.communityFee)
      revert IOperaPoolErrors.invalidNewCommunityFee();
    globalState.communityFee = newCommunityFee;
  }

  /// @inheritdoc IOperaPoolPermissionedActions
  function setFedReserves(uint256 _r0, uint256 _r1) external override {
    internalState.reserve0 = _r0;
    internalState.reserve1 = _r1;
  }

  /// @inheritdoc IOperaPoolPermissionedActions
  function setTickSpacing(int24 newTickSpacing) external override {
    if (newTickSpacing <= 0 || newTickSpacing > Constants.MAX_TICK_SPACING || tickSpacing == newTickSpacing)
      revert IOperaPoolErrors.invalidNewTickSpacing();
    tickSpacing = newTickSpacing;
  }

  /// @inheritdoc IOperaPoolPermissionedActions
  function setPlugin(address newPluginAddress) external override {
    require(msg.sender == owner);
    plugin = newPluginAddress;
  }

  /// @inheritdoc IOperaPoolPermissionedActions
  function setPluginConfig(uint8 newConfig) external override {
    require(msg.sender == owner || msg.sender == plugin);
    globalState.pluginConfig = newConfig;
  }

  /// @inheritdoc IOperaPoolPermissionedActions
  function setFee(uint16 newFee) external override {
    require(msg.sender == owner || msg.sender == plugin);
    bool isDynamicFeeEnabled = globalState.pluginConfig & uint8(Plugins.DYNAMIC_FEE) != 0;

    if (msg.sender == plugin) {
      require(isDynamicFeeEnabled);
    } else {
      require(!isDynamicFeeEnabled && msg.sender == owner);
    }

    globalState.fee = newFee;
  }

  function setCommunityVault(address newCommunityVault) external override {
    communityVault = newCommunityVault;
  }

  /// @inheritdoc IOperaPoolPermissionedActions
  function sync() external pure override {
    revert('Not implemented');
  }

  /// @inheritdoc IOperaPoolPermissionedActions
  function skim() external pure override {
    revert('Not implemented');
  }
}
