// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import './libraries/SafeTransfer.sol';
import './libraries/FullMath.sol';

import './interfaces/IOperaFactory.sol';
import './interfaces/vault/IOperaCommunityVault.sol';

/// @title Opera community fee vault
/// @notice Community fee from pools is sent here, if it is enabled
/// @dev Role system is used to withdraw tokens
/// @dev Version: Opera Insider 1.1
contract OperaCommunityVault is IOperaCommunityVault {
  /// @dev The role can be granted in OperaFactory
  bytes32 public constant COMMUNITY_FEE_WITHDRAWER_ROLE = keccak256('COMMUNITY_FEE_WITHDRAWER');
  /// @dev The role can be granted in OperaFactory
  bytes32 public constant COMMUNITY_FEE_VAULT_ADMINISTRATOR = keccak256('COMMUNITY_FEE_VAULT_ADMINISTRATOR');
  address private immutable factory;

  /// @notice Address to which community fees are sent from vault
  address public communityFeeReceiver;
  /// @notice The percentage of the protocol fee that Opera will receive
  /// @dev Value in thousandths,i.e. 1e-3
  uint16 public operaFee;
  /// @notice Represents whether there is a new Opera fee proposal or not
  bool public hasNewOperaFeeProposal;
  /// @notice Suggested Opera fee value
  uint16 public proposedNewOperaFee;
  /// @notice Address of recipient Opera part of community fee
  address public operaFeeReceiver;
  /// @notice Address of Opera fee manager
  address public operaFeeManager;
  address private _pendingOperaFeeManager;

  uint16 private constant OPERA_FEE_DENOMINATOR = 1000;

  modifier onlyAdministrator() {
    require(IOperaFactory(factory).hasRoleOrOwner(COMMUNITY_FEE_VAULT_ADMINISTRATOR, msg.sender), 'only administrator');
    _;
  }

  modifier onlyWithdrawer() {
    require(msg.sender == operaFeeManager || IOperaFactory(factory).hasRoleOrOwner(COMMUNITY_FEE_WITHDRAWER_ROLE, msg.sender), 'only withdrawer');
    _;
  }

  modifier onlyOperaFeeManager() {
    require(msg.sender == operaFeeManager, 'only opera fee manager');
    _;
  }

  constructor(address _factory, address _operaFeeManager) {
    (factory, operaFeeManager) = (_factory, _operaFeeManager);
  }

  /// @inheritdoc IOperaCommunityVault
  function withdraw(address token, uint256 amount) external override onlyWithdrawer {
    (uint16 _operaFee, address _operaFeeReceiver, address _communityFeeReceiver) = _readAndVerifyWithdrawSettings();
    _withdraw(token, _communityFeeReceiver, amount, _operaFee, _operaFeeReceiver);
  }

  /// @inheritdoc IOperaCommunityVault
  function withdrawTokens(WithdrawTokensParams[] calldata params) external override onlyWithdrawer {
    uint256 paramsLength = params.length;
    (uint16 _operaFee, address _operaFeeReceiver, address _communityFeeReceiver) = _readAndVerifyWithdrawSettings();

    unchecked {
      for (uint256 i; i < paramsLength; ++i) _withdraw(params[i].token, _communityFeeReceiver, params[i].amount, _operaFee, _operaFeeReceiver);
    }
  }

  function _readAndVerifyWithdrawSettings() private view returns (uint16 _operaFee, address _operaFeeReceiver, address _communityFeeReceiver) {
    (_operaFee, _operaFeeReceiver, _communityFeeReceiver) = (operaFee, operaFeeReceiver, communityFeeReceiver);
    if (_operaFee != 0) require(_operaFeeReceiver != address(0), 'invalid opera fee receiver');
    require(_communityFeeReceiver != address(0), 'invalid receiver');
  }

  function _withdraw(address token, address to, uint256 amount, uint16 _operaFee, address _operaFeeReceiver) private {
    uint256 withdrawAmount = amount;
    if (_operaFee != 0) {
      uint256 operaFeeAmount = FullMath.mulDivRoundingUp(withdrawAmount, _operaFee, OPERA_FEE_DENOMINATOR);
      withdrawAmount -= operaFeeAmount;
      SafeTransfer.safeTransfer(token, _operaFeeReceiver, operaFeeAmount);
      emit OperaTokensWithdrawal(token, _operaFeeReceiver, operaFeeAmount);
    }

    SafeTransfer.safeTransfer(token, to, withdrawAmount);
    emit TokensWithdrawal(token, to, withdrawAmount);
  }

  // ### opera factory owner permissioned actions ###

  /// @inheritdoc IOperaCommunityVault
  function acceptOperaFeeChangeProposal(uint16 newOperaFee) external override onlyAdministrator {
    require(hasNewOperaFeeProposal, 'not proposed');
    require(newOperaFee == proposedNewOperaFee, 'invalid new fee');

    // note that the new value will be used for previously accumulated tokens that have not yet been withdrawn
    operaFee = newOperaFee;
    (proposedNewOperaFee, hasNewOperaFeeProposal) = (0, false);
    emit OperaFee(newOperaFee);
  }

  /// @inheritdoc IOperaCommunityVault
  function changeCommunityFeeReceiver(address newCommunityFeeReceiver) external override onlyAdministrator {
    require(newCommunityFeeReceiver != address(0));
    require(newCommunityFeeReceiver != communityFeeReceiver);
    communityFeeReceiver = newCommunityFeeReceiver;
    emit CommunityFeeReceiver(newCommunityFeeReceiver);
  }

  // ### opera fee manager permissioned actions ###

  /// @inheritdoc IOperaCommunityVault
  function transferOperaFeeManagerRole(address _newOperaFeeManager) external override onlyOperaFeeManager {
    _pendingOperaFeeManager = _newOperaFeeManager;
    emit PendingOperaFeeManager(_newOperaFeeManager);
  }

  /// @inheritdoc IOperaCommunityVault
  function acceptOperaFeeManagerRole() external override {
    require(msg.sender == _pendingOperaFeeManager);
    (_pendingOperaFeeManager, operaFeeManager) = (address(0), msg.sender);
    emit OperaFeeManager(msg.sender);
  }

  /// @inheritdoc IOperaCommunityVault
  function proposeOperaFeeChange(uint16 newOperaFee) external override onlyOperaFeeManager {
    require(newOperaFee <= OPERA_FEE_DENOMINATOR);
    require(newOperaFee != proposedNewOperaFee && newOperaFee != operaFee);
    (proposedNewOperaFee, hasNewOperaFeeProposal) = (newOperaFee, true);
    emit OperaFeeProposal(newOperaFee);
  }

  /// @inheritdoc IOperaCommunityVault
  function cancelOperaFeeChangeProposal() external override onlyOperaFeeManager {
    (proposedNewOperaFee, hasNewOperaFeeProposal) = (0, false);
    emit CancelOperaFeeProposal();
  }

  /// @inheritdoc IOperaCommunityVault
  function changeOperaFeeReceiver(address newOperaFeeReceiver) external override onlyOperaFeeManager {
    require(newOperaFeeReceiver != address(0));
    require(newOperaFeeReceiver != operaFeeReceiver);
    operaFeeReceiver = newOperaFeeReceiver;
    emit OperaFeeReceiver(newOperaFeeReceiver);
  }
}
