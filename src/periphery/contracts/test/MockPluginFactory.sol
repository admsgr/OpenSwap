// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import './MockPlugin.sol';

import '@openswap/opera-insider-core/contracts/interfaces/plugin/IOperaPluginFactory.sol';
import '@openswap/opera-insider-core/contracts/interfaces/IOperaFactory.sol';

contract MockPluginFactory is IOperaPluginFactory {
    address public immutable operaFactory;

    mapping(address poolAddress => address pluginAddress) public pluginByPool;

    constructor(address _operaFactory) {
        operaFactory = _operaFactory;
    }

    /// @inheritdoc IOperaPluginFactory
    function beforeCreatePoolHook(
        address pool,
        address,
        address,
        address,
        address,
        bytes calldata
    ) external override returns (address) {
        require(msg.sender == operaFactory);
        return _createPlugin(pool);
    }

    /// @inheritdoc IOperaPluginFactory
    function afterCreatePoolHook(address, address, address) external view override {
        require(msg.sender == operaFactory);
    }

    //   function createPluginForExistingPool(address token0, address token1) external override returns (address) {
    //     IOperaFactory factory = IOperaFactory(operaFactory);
    //     require(factory.hasRoleOrOwner(factory.POOLS_ADMINISTRATOR_ROLE(), msg.sender));

    //     address pool = factory.poolByPair(token0, token1);
    //     require(pool != address(0), 'Pool not exist');

    //     return _createPlugin(pool);
    //   }

    function _createPlugin(address pool) internal returns (address) {
        require(pluginByPool[pool] == address(0), 'Already created');
        MockPlugin mockPlugin = new MockPlugin();
        pluginByPool[pool] = address(mockPlugin);
        return address(mockPlugin);
    }
}
