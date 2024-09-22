// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;
pragma abicoder v1;

import '../interfaces/vault/IOperaVaultFactory.sol';

/// @title Opera vault factory stub
/// @notice This contract is used to set OperaCommunityVault as communityVault in new pools
contract FaultyVaultFactoryStub is IOperaVaultFactory {
  /// @notice the address of OperaCommunityVault
  address public immutable defaultOperaCommunityVault;

  constructor(address _operaCommunityVault) {
    defaultOperaCommunityVault = _operaCommunityVault;
  }

  /// @inheritdoc IOperaVaultFactory
  function getVaultForPool(address) external view override returns (address) {
    return defaultOperaCommunityVault;
  }

  /// @inheritdoc IOperaVaultFactory
  function createVaultForPool(address, address, address, address, address) external view override returns (address) {
    return defaultOperaCommunityVault;
  }
}
