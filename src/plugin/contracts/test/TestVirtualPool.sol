// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;
pragma abicoder v1;

import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';
import '../interfaces/IOperaVirtualPool.sol';

contract TestVirtualPool is IOperaVirtualPool {
  struct Data {
    int24 tick;
  }

  Data[] private data;

  function crossTo(int24, bool) external override returns (bool) {
    for (uint i; i < 100; i++) {
      (, int24 poolTick, , , , ) = IOperaPool(msg.sender).globalState();
      data.push(Data(poolTick));
    }

    return true;
  }
}
