

# IOperaVaultFactory


The interface for the Opera Vault Factory

This contract can be used for automatic vaults creation

*Developer note: Version: Opera Insider*


## Functions
### getVaultForPool

```solidity
function getVaultForPool(address pool) external view returns (address communityFeeVault)
```
**Selector**: `0x7570e389`

returns address of the community fee vault for the pool

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | the address of Opera Insider pool |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| communityFeeVault | address | the address of community fee vault |

### createVaultForPool

```solidity
function createVaultForPool(address pool, address creator, address deployer, address token0, address token1) external returns (address communityFeeVault)
```
**Selector**: `0xb8a1d3c6`

creates the community fee vault for the pool if needed

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | the address of Opera Insider pool |
| creator | address |  |
| deployer | address |  |
| token0 | address |  |
| token1 | address |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| communityFeeVault | address | the address of community fee vault |

