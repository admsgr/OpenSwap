// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import '../libraries/TickMath.sol';

import '../interfaces/callback/IOperaSwapCallback.sol';

import '../interfaces/IOperaPool.sol';
import '../interfaces/IOperaFactory.sol';

contract TestOperaReentrantCallee is IOperaSwapCallback {
  bytes4 private constant desiredSelector = bytes4(keccak256(bytes('locked()')));

  function swapToReenter(address pool) external {
    unchecked {
      IOperaPool(pool).swap(address(0), false, 1, TickMath.MAX_SQRT_RATIO - 1, new bytes(0));
    }
  }

  function operaSwapCallback(int256, int256, bytes calldata) external override {
    int24 tickSpacing = IOperaPool(msg.sender).tickSpacing();

    // try to reenter swap
    try IOperaPool(msg.sender).swap(address(0), false, 1, 0, new bytes(0)) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter swap supporting fee
    try IOperaPool(msg.sender).swapWithPaymentInAdvance(address(0), address(0), false, 1, 0, new bytes(0)) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter mint
    try IOperaPool(msg.sender).mint(address(0), address(0), 0, tickSpacing, 100, new bytes(0)) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter collect
    try IOperaPool(msg.sender).collect(address(0), 0, 0, 0, 0) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter burn
    try IOperaPool(msg.sender).burn(0, tickSpacing, 0, new bytes(0)) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter flash
    try IOperaPool(msg.sender).flash(address(0), 0, 0, new bytes(0)) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter setCommunityFee
    try IOperaPool(msg.sender).setCommunityFee(10) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter setTickSpacing
    try IOperaPool(msg.sender).setTickSpacing(20) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter setPlugin
    try IOperaPool(msg.sender).setPlugin(address(this)) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter setPluginConfig
    try IOperaPool(msg.sender).setPluginConfig(1) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter setFee
    try IOperaPool(msg.sender).setFee(120) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter setCommunityFeeVault
    try IOperaPool(msg.sender).setCommunityVault(address(this)) {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to get AMM state
    try IOperaPool(msg.sender).safelyGetStateOfAMM() {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter sync
    try IOperaPool(msg.sender).sync() {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    // try to reenter skim
    try IOperaPool(msg.sender).skim() {} catch (bytes memory reason) {
      require(bytes4(reason) == desiredSelector);
    }

    require(IOperaPool(msg.sender).isUnlocked() == false);

    require(false, 'Unable to reenter');
  }

  // factory reentrancy
  address public factory;
  address public tokenA;
  address public tokenB;

  function beforeCreatePoolHook(address, address, address, address, address, bytes calldata data) external returns (address plugin) {
    plugin = address(0);
    _createCustomPool(factory, tokenA, tokenB, data);
  }

  function createCustomPool(address _factory, address _tokenA, address _tokenB, bytes calldata data) external returns (address pool) {
    factory = _factory;
    tokenA = _tokenA;
    tokenB = _tokenB;
    pool = _createCustomPool(_factory, _tokenA, _tokenB, data);
  }

  function _createCustomPool(address _factory, address _tokenA, address _tokenB, bytes calldata data) internal returns (address pool) {
    pool = IOperaFactory(_factory).createCustomPool(address(this), msg.sender, _tokenA, _tokenB, data);
  }
}
