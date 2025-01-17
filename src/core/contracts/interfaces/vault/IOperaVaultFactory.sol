// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Opera Vault Factory
/// @notice This contract can be used for automatic vaults creation
/// @dev Version: Opera Insider
interface IOperaVaultFactory {
  /// @notice returns address of the community fee vault for the pool
  /// @param pool the address of Opera Insider pool
  /// @return communityFeeVault the address of community fee vault
  function getVaultForPool(address pool) external view returns (address communityFeeVault);

  /// @notice creates the community fee vault for the pool if needed
  /// @param pool the address of Opera Insider pool
  /// @return communityFeeVault the address of community fee vault
  function createVaultForPool(
    address pool,
    address creator,
    address deployer,
    address token0,
    address token1
  ) external returns (address communityFeeVault);
}
