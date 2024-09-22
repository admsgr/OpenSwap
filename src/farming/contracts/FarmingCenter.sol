// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';
import '@openswap/opera-insider-core/contracts/interfaces/IERC20Minimal.sol';
import '@openswap/opera-insider-periphery/contracts/interfaces/IPositionFollower.sol';
import '@openswap/opera-insider-periphery/contracts/interfaces/INonfungiblePositionManager.sol';
import '@openswap/opera-insider-periphery/contracts/base/Multicall.sol';
import '@openswap/opera-insider-periphery/contracts/libraries/PoolAddress.sol';
import '@openswap/opera-insider-base-plugin/contracts/interfaces/plugins/IFarmingPlugin.sol';

import './interfaces/IFarmingCenter.sol';
import './libraries/IncentiveId.sol';

/// @title Opera Insider 1.1 main farming contract
/// @dev Manages farmings and performs entry, exit and other actions.
contract FarmingCenter is IFarmingCenter, IPositionFollower, Multicall {
  /// @inheritdoc IFarmingCenter
  IOperaEternalFarming public immutable override eternalFarming;
  /// @inheritdoc IFarmingCenter
  INonfungiblePositionManager public immutable override nonfungiblePositionManager;
  /// @inheritdoc IFarmingCenter
  address public immutable override operaPoolDeployer;

  /// @inheritdoc IFarmingCenter
  mapping(address poolAddress => address virtualPoolAddress) public override virtualPoolAddresses;

  /// @inheritdoc IFarmingCenter
  mapping(uint256 tokenId => bytes32 incentiveId) public override deposits;

  /// @inheritdoc IFarmingCenter
  mapping(bytes32 incentiveId => IncentiveKey incentiveKey) public override incentiveKeys;

  constructor(IOperaEternalFarming _eternalFarming, INonfungiblePositionManager _nonfungiblePositionManager) {
    eternalFarming = _eternalFarming;
    nonfungiblePositionManager = _nonfungiblePositionManager;
    operaPoolDeployer = _nonfungiblePositionManager.poolDeployer();
  }

  modifier isApprovedOrOwner(uint256 tokenId) {
    require(nonfungiblePositionManager.isApprovedOrOwner(msg.sender, tokenId), 'Not approved for token');
    _;
  }

  /// @inheritdoc IFarmingCenter
  function enterFarming(IncentiveKey memory key, uint256 tokenId) external override isApprovedOrOwner(tokenId) {
    bytes32 incentiveId = IncentiveId.compute(key);
    if (address(incentiveKeys[incentiveId].pool) == address(0)) incentiveKeys[incentiveId] = key;

    require(deposits[tokenId] == bytes32(0), 'Token already farmed');
    deposits[tokenId] = incentiveId;
    nonfungiblePositionManager.switchFarmingStatus(tokenId, true);

    IOperaEternalFarming(eternalFarming).enterFarming(key, tokenId);
  }

  /// @inheritdoc IFarmingCenter
  function exitFarming(IncentiveKey memory key, uint256 tokenId) external override isApprovedOrOwner(tokenId) {
    _exitFarming(key, tokenId, nonfungiblePositionManager.ownerOf(tokenId));
  }

  function _exitFarming(IncentiveKey memory key, uint256 tokenId, address tokenOwner) private {
    require(deposits[tokenId] == IncentiveId.compute(key), 'Invalid incentiveId');
    _switchFarmingStatusOff(tokenId);

    IOperaEternalFarming(eternalFarming).exitFarming(key, tokenId, tokenOwner);
  }

  function _switchFarmingStatusOff(uint256 tokenId) internal {
    deposits[tokenId] = bytes32(0);
    if (nonfungiblePositionManager.tokenFarmedIn(tokenId) == address(this)) {
      nonfungiblePositionManager.switchFarmingStatus(tokenId, false);
    }
  }

  /// @inheritdoc IPositionFollower
  function applyLiquidityDelta(uint256 tokenId, int256) external override {
    _updatePosition(tokenId);
  }

  function _updatePosition(uint256 tokenId) private {
    require(msg.sender == address(nonfungiblePositionManager), 'Only nonfungiblePosManager');

    bytes32 _eternalIncentiveId = deposits[tokenId];
    if (_eternalIncentiveId != bytes32(0)) {
      address tokenOwner = nonfungiblePositionManager.ownerOf(tokenId);
      (, , , , , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(tokenId);

      IncentiveKey memory key = incentiveKeys[_eternalIncentiveId];

      if (liquidity == 0 || virtualPoolAddresses[address(key.pool)] == address(0)) {
        _exitFarming(key, tokenId, tokenOwner); // nft burned or incentive deactivated, exit completely
      } else {
        IOperaEternalFarming(eternalFarming).exitFarming(key, tokenId, tokenOwner);

        if (
          IOperaEternalFarming(eternalFarming).isIncentiveDeactivated(IncentiveId.compute(key)) ||
          IOperaEternalFarming(eternalFarming).isEmergencyWithdrawActivated()
        ) {
          // exit completely if the incentive has stopped (manually or automatically) or there is emergency
          _switchFarmingStatusOff(tokenId);
        } else {
          // reenter with new liquidity value
          IOperaEternalFarming(eternalFarming).enterFarming(key, tokenId);
        }
      }
    }
  }

  /// @inheritdoc IFarmingCenter
  function collectRewards(
    IncentiveKey memory key,
    uint256 tokenId
  ) external override isApprovedOrOwner(tokenId) returns (uint256 reward, uint256 bonusReward) {
    (reward, bonusReward) = eternalFarming.collectRewards(key, tokenId, nonfungiblePositionManager.ownerOf(tokenId));
  }

  /// @inheritdoc IFarmingCenter
  function claimReward(IERC20Minimal rewardToken, address to, uint256 amountRequested) external override returns (uint256 rewardBalanceBefore) {
    rewardBalanceBefore = eternalFarming.claimRewardFrom(rewardToken, msg.sender, to, amountRequested);
  }

  /// @inheritdoc IFarmingCenter
  function connectVirtualPoolToPlugin(address newVirtualPool, IFarmingPlugin plugin) external override {
    IOperaPool pool = _checkParamsForVirtualPoolToggle(newVirtualPool, plugin);
    require(plugin.incentive() == address(0), 'Another incentive is connected');
    plugin.setIncentive(newVirtualPool); // revert is possible if the plugin does not allow
    virtualPoolAddresses[address(pool)] = newVirtualPool;
  }

  /// @inheritdoc IFarmingCenter
  function disconnectVirtualPoolFromPlugin(address virtualPool, IFarmingPlugin plugin) external override {
    IOperaPool pool = _checkParamsForVirtualPoolToggle(virtualPool, plugin);
    if (plugin.incentive() == virtualPool) plugin.setIncentive(address(0)); // plugin _should_ allow to disconnect incentive
    virtualPoolAddresses[address(pool)] = address(0);
  }

  /// @dev checks input params and fetches corresponding Opera Insider pool
  function _checkParamsForVirtualPoolToggle(address virtualPool, IFarmingPlugin plugin) internal view returns (IOperaPool pool) {
    require(msg.sender == address(eternalFarming), 'Only farming can call this');
    require(virtualPool != address(0), 'Zero address as virtual pool');
    pool = IOperaPool(plugin.pool());
    require(
      address(pool) == PoolAddress.computeAddress(operaPoolDeployer, PoolAddress.PoolKey(address(0), pool.token0(), pool.token1())),
      'Invalid pool'
    );
  }
}
