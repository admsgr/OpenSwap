// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IOperaPoolActions#flash
/// @notice Any contract that calls IOperaPoolActions#flash must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IOperaFlashCallback {
  /// @notice Called to `msg.sender` after transferring to the recipient from IOperaPool#flash.
  /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
  /// The caller of this method _must_ be checked to be a OperaPool deployed by the canonical OperaFactory.
  /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
  /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
  /// @param data Any data passed through by the caller via the IOperaPoolActions#flash call
  function operaFlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external;
}
