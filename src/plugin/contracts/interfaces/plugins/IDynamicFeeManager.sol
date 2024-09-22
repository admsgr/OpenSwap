// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import '@openswap/opera-insider-core/contracts/interfaces/plugin/IOperaDynamicFeePlugin.sol';
import '../../base/OperaFeeConfiguration.sol';

/// @title The interface for the Opera dynamic fee manager
/// @dev This contract calculates adaptive fee
interface IDynamicFeeManager is IOperaDynamicFeePlugin {
  /// @notice Emitted when the fee configuration is changed
  /// @param feeConfig The structure with dynamic fee parameters
  /// @dev See the AdaptiveFee struct for more details
  event FeeConfiguration(OperaFeeConfiguration feeConfig);

  /// @notice Current dynamic fee configuration
  /// @dev See the AdaptiveFee struct for more details
  function feeConfig() external view returns (uint16 alpha1, uint16 alpha2, uint32 beta1, uint32 beta2, uint16 gamma1, uint16 gamma2, uint16 baseFee);

  /// @notice Changes fee configuration for the pool
  function changeFeeConfiguration(OperaFeeConfiguration calldata feeConfig) external;
}
