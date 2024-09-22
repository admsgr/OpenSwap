// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Opera community fee vault
/// @notice Community fee from pools is sent here, if it is enabled
/// @dev Version: Opera Insider
interface IOperaCommunityVault {
  /// @notice Event emitted when a fees has been claimed
  /// @param token The address of token fee
  /// @param to The address where claimed rewards were sent to
  /// @param amount The amount of fees tokens claimed by communityFeeReceiver
  event TokensWithdrawal(address indexed token, address indexed to, uint256 amount);

  /// @notice Event emitted when a fees has been claimed
  /// @param token The address of token fee
  /// @param to The address where claimed rewards were sent to
  /// @param amount The amount of fees tokens claimed by Opera
  event OperaTokensWithdrawal(address indexed token, address indexed to, uint256 amount);

  /// @notice Emitted when a OperaFeeReceiver address changed
  /// @param newOperaFeeReceiver New Opera fee receiver address
  event OperaFeeReceiver(address newOperaFeeReceiver);

  /// @notice Emitted when a OperaFeeManager address change proposed
  /// @param pendingOperaFeeManager New pending Opera fee manager address
  event PendingOperaFeeManager(address pendingOperaFeeManager);

  /// @notice Emitted when a new Opera fee value proposed
  /// @param proposedNewOperaFee The new proposed Opera fee value
  event OperaFeeProposal(uint16 proposedNewOperaFee);

  /// @notice Emitted when a Opera fee proposal canceled
  event CancelOperaFeeProposal();

  /// @notice Emitted when a OperaFeeManager address changed
  /// @param newOperaFeeManager New Opera fee manager address
  event OperaFeeManager(address newOperaFeeManager);

  /// @notice Emitted when the Opera fee is changed
  /// @param newOperaFee The new Opera fee value
  event OperaFee(uint16 newOperaFee);

  /// @notice Emitted when a CommunityFeeReceiver address changed
  /// @param newCommunityFeeReceiver New fee receiver address
  event CommunityFeeReceiver(address newCommunityFeeReceiver);

  /// @notice Withdraw protocol fees from vault
  /// @dev Can only be called by operaFeeManager or communityFeeReceiver
  /// @param token The token address
  /// @param amount The amount of token
  function withdraw(address token, uint256 amount) external;

  struct WithdrawTokensParams {
    address token;
    uint256 amount;
  }

  /// @notice Withdraw protocol fees from vault. Used to claim fees for multiple tokens
  /// @dev Can be called by operaFeeManager or communityFeeReceiver
  /// @param params Array of WithdrawTokensParams objects containing token addresses and amounts to withdraw
  function withdrawTokens(WithdrawTokensParams[] calldata params) external;

  // ### opera factory owner permissioned actions ###

  /// @notice Accepts the proposed new Opera fee
  /// @dev Can only be called by the factory owner.
  /// The new value will also be used for previously accumulated tokens that have not yet been withdrawn
  /// @param newOperaFee New Opera fee value
  function acceptOperaFeeChangeProposal(uint16 newOperaFee) external;

  /// @notice Change community fee receiver address
  /// @dev Can only be called by the factory owner
  /// @param newCommunityFeeReceiver New community fee receiver address
  function changeCommunityFeeReceiver(address newCommunityFeeReceiver) external;

  // ### opera fee manager permissioned actions ###

  /// @notice Transfers Opera fee manager role
  /// @param _newOperaFeeManager new Opera fee manager address
  function transferOperaFeeManagerRole(address _newOperaFeeManager) external;

  /// @notice accept Opera FeeManager role
  function acceptOperaFeeManagerRole() external;

  /// @notice Proposes new Opera fee value for protocol
  /// @dev the new value will also be used for previously accumulated tokens that have not yet been withdrawn
  /// @param newOperaFee new Opera fee value
  function proposeOperaFeeChange(uint16 newOperaFee) external;

  /// @notice Cancels Opera fee change proposal
  function cancelOperaFeeChangeProposal() external;

  /// @notice Change Opera community fee part receiver
  /// @param newOperaFeeReceiver The address of new Opera fee receiver
  function changeOperaFeeReceiver(address newOperaFeeReceiver) external;
}
