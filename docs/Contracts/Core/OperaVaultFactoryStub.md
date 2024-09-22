

# OperaVaultFactoryStub


Opera vault factory stub

This contract is used to set OperaCommunityVault as communityVault in new pools

**Inherits:** [IOperaVaultFactory](interfaces/vault/IOperaVaultFactory.md)

## Public variables
### defaultOperaCommunityVault
```solidity
address immutable defaultOperaCommunityVault
```
**Selector**: `0x2477fbec`

the address of OperaCommunityVault



## Functions
### constructor

```solidity
constructor(address _operaCommunityVault) public
```



| Name | Type | Description |
| ---- | ---- | ----------- |
| _operaCommunityVault | address |  |

### getVaultForPool

```solidity
function getVaultForPool(address) external view returns (address)
```
**Selector**: `0x7570e389`

returns address of the community fee vault for the pool

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address |  |

### createVaultForPool

```solidity
function createVaultForPool(address, address, address, address, address) external view returns (address)
```
**Selector**: `0xb8a1d3c6`

creates the community fee vault for the pool if needed

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | address |  |
|  | address |  |
|  | address |  |
|  | address |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address |  |

