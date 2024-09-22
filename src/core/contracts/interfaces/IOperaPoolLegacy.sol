// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IOperaPoolImmutables.sol';
import './pool/IOperaPoolState.sol';
import './pool/IOperaPoolActions.sol';
import './pool/IOperaPoolPermissionedActions.sol';
import './pool/IOperaPoolEvents.sol';

/// @title The legacy interface for a Opera Pool
/// @dev The pool interface is broken up into many smaller pieces.
/// This interface does not include custom error definitions and can be used in older versions of Solidity.
/// Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IOperaPoolLegacy is IOperaPoolImmutables, IOperaPoolState, IOperaPoolActions, IOperaPoolPermissionedActions, IOperaPoolEvents {
  // used only for combining interfaces
}
