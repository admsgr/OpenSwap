// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import {IOperaCustomPoolEntryPoint, IOperaPluginFactory} from './interfaces/IOperaCustomPoolEntryPoint.sol';
import {IOperaPool} from '@openswap/opera-insider-core/contracts/interfaces/IOperaPool.sol';
import {IOperaFactory} from '@openswap/opera-insider-core/contracts/interfaces/IOperaFactory.sol';

/// @title Opera custom pool entry point
/// @notice Is used to create custom pools
/// @dev Version: Opera Insider 2.0
contract OperaCustomPoolEntryPoint is IOperaCustomPoolEntryPoint {
    /// @inheritdoc IOperaCustomPoolEntryPoint
    address public immutable override factory;

    modifier onlyCustomDeployer(address pool) {
        _checkIfDeployer(pool);
        _;
    }

    constructor(address _factory) {
        require(_factory != address(0));
        factory = _factory;
    }

    /// @inheritdoc IOperaCustomPoolEntryPoint
    function createCustomPool(
        address deployer,
        address creator,
        address tokenA,
        address tokenB,
        bytes calldata data
    ) external override returns (address customPool) {
        require(msg.sender == deployer, 'Only deployer');

        return IOperaFactory(factory).createCustomPool(deployer, creator, tokenA, tokenB, data);
    }

    /// @inheritdoc IOperaPluginFactory
    function beforeCreatePoolHook(
        address pool,
        address creator,
        address deployer,
        address token0,
        address token1,
        bytes calldata data
    ) external override returns (address) {
        require(msg.sender == factory, 'Only factory');

        // all additional custom logic should be implemented in `deployer` smart contract
        return IOperaPluginFactory(deployer).beforeCreatePoolHook(pool, creator, deployer, token0, token1, data);
    }

    /// @inheritdoc IOperaPluginFactory
    function afterCreatePoolHook(address plugin, address pool, address deployer) external override {
        require(msg.sender == factory, 'Only factory');

        IOperaPluginFactory(deployer).afterCreatePoolHook(plugin, pool, deployer);
    }

    // ####### Permissioned actions #######
    // OperaCustomPoolEntryPoint must have a "POOLS_ADMINISTRATOR" role to be able to use permissioned actions

    /// @inheritdoc IOperaCustomPoolEntryPoint
    function setTickSpacing(address pool, int24 newTickSpacing) external override onlyCustomDeployer(pool) {
        IOperaPool(pool).setTickSpacing(newTickSpacing);
    }

    /// @inheritdoc IOperaCustomPoolEntryPoint
    function setPlugin(address pool, address newPluginAddress) external override onlyCustomDeployer(pool) {
        IOperaPool(pool).setPlugin(newPluginAddress);
    }

    /// @inheritdoc IOperaCustomPoolEntryPoint
    function setPluginConfig(address pool, uint8 newConfig) external override onlyCustomDeployer(pool) {
        IOperaPool(pool).setPluginConfig(newConfig);
    }

    /// @inheritdoc IOperaCustomPoolEntryPoint
    function setFee(address pool, uint16 newFee) external override onlyCustomDeployer(pool) {
        IOperaPool(pool).setFee(newFee);
    }

    function _checkIfDeployer(address pool) internal view {
        address token0 = IOperaPool(pool).token0();
        address token1 = IOperaPool(pool).token1();
        require(pool == IOperaFactory(factory).customPoolByPair(msg.sender, token0, token1), 'Only deployer');
    }
}
