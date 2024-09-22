// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@openswap/opera-insider-core/contracts/interfaces/plugin/IOperaPluginFactory.sol';

/// @title An interface for a contract that is used to deploy and manage Opera Insider custom pools
/// @dev This contract should be called by every custom pool deployer to create new custom pools or manage existing ones.
interface IOperaCustomPoolEntryPoint is IOperaPluginFactory {
    /// @notice Returns the address of corresponding OperaFactory contract
    /// @return factory The address of OperaFactory
    function factory() external view returns (address factory);

    /// @notice Using for custom pools creation
    /// @param deployer The address of plugin deployer, also used for custom pool address calculation
    /// @param creator The initiator of custom pool creation
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param data The additional data bytes
    function createCustomPool(
        address deployer,
        address creator,
        address tokenA,
        address tokenB,
        bytes calldata data
    ) external returns (address customPool);

    /// @notice Changes the tick spacing value in the Opera Insider custom pool
    /// @dev Only corresponding custom pool deployer contract can call this function
    /// @param pool The address of the Opera Insider custom pool
    /// @param newTickSpacing The new tick spacing value
    function setTickSpacing(address pool, int24 newTickSpacing) external;

    /// @notice Changes the plugin address in the Opera Insider custom pool
    /// @dev Only corresponding custom pool deployer contract can call this function
    /// @param pool The address of the Opera Insider custom pool
    /// @param newPluginAddress The new plugin address
    function setPlugin(address pool, address newPluginAddress) external;

    /// @notice Changes the plugin configuration in the Opera Insider custom pool
    /// @dev Only corresponding custom pool deployer contract can call this function
    /// @param pool The address of the Opera Insider custom pool
    /// @param newConfig The new plugin configuration bitmap
    function setPluginConfig(address pool, uint8 newConfig) external;

    /// @notice Changes the fee value in the Opera Insider custom pool
    /// @dev Only corresponding custom pool deployer contract can call this function.
    /// Fee can be changed manually only if pool does not have "dynamic fee" configuration
    /// @param pool The address of the Opera Insider custom pool
    /// @param newFee The new fee value
    function setFee(address pool, uint16 newFee) external;
}
