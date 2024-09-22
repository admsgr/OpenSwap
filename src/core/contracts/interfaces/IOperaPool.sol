// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import './pool/IOperaPoolImmutables.sol';
import './pool/IOperaPoolState.sol';
import './pool/IOperaPoolActions.sol';
import './pool/IOperaPoolPermissionedActions.sol';
import './pool/IOperaPoolEvents.sol';
import './pool/IOperaPoolErrors.sol';

/// @title The interface for a Opera Pool
/// @dev The pool interface is broken up into many smaller pieces.
/// This interface includes custom error definitions and cannot be used in older versions of Solidity.
/// For older versions of Solidity use #IOperaPoolLegacy
/// Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IOperaPool is
  IOperaPoolImmutables,
  IOperaPoolState,
  IOperaPoolActions,
  IOperaPoolPermissionedActions,
  IOperaPoolEvents,
  IOperaPoolErrors
{
  // used only for combining interfaces
}
