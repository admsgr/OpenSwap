// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.20;

import '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';
import '../libraries/PoolTicksCounter.sol';

contract PoolTicksCounterTest {
    using PoolTicksCounter for IOperaPool;

    mapping(int16 => uint256) public tickTable;

    int16 public tickSpacing;

    function setTickTableWord(int16 index, uint256 value) external {
        tickTable[index] = value;
    }

    function setTickSpacing(int16 newValue) external {
        tickSpacing = newValue;
    }

    function countInitializedTicksCrossed(
        IOperaPool pool,
        int24 tickBefore,
        int24 tickAfter
    ) external view returns (uint32 initializedTicksCrossed) {
        return pool.countInitializedTicksCrossed(tickBefore, tickAfter);
    }
}
