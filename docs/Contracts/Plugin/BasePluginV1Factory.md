

# BasePluginV1Factory


Opera Insider 1.1 default plugin factory

This contract creates Opera default plugins for Opera liquidity pools

*Developer note: This plugin factory can only be used for Opera base pools*

**Inherits:** [IBasePluginV1Factory](interfaces/IBasePluginV1Factory.md)
## Modifiers
### onlyAdministrator

```solidity
modifier onlyAdministrator()
```




## Public variables
### OPERA_BASE_PLUGIN_FACTORY_ADMINISTRATOR
```solidity
bytes32 constant OPERA_BASE_PLUGIN_FACTORY_ADMINISTRATOR = 0x41eb27091fcc9fc2c526e57417010b389af724bce10177f80e11bd033e28e595
```
**Selector**: `0x39889881`

The hash of &#x27;OPERA_BASE_PLUGIN_FACTORY_ADMINISTRATOR&#x27; used as role

*Developer note: allows to change settings of BasePluginV1Factory*

### operaFactory
```solidity
address immutable operaFactory
```
**Selector**: `0x9d8775e2`

Returns the address of OperaFactory


### defaultFeeConfiguration
```solidity
struct OperaFeeConfiguration defaultFeeConfiguration
```
**Selector**: `0x4e09a96a`

Current default dynamic fee configuration

*Developer note: See the AdaptiveFee struct for more details about params.
This value is set by default in new plugins*

### farmingAddress
```solidity
address farmingAddress
```
**Selector**: `0x8a2ade58`

Returns current farming address


### pluginByPool
```solidity
mapping(address => address) pluginByPool
```
**Selector**: `0xcdef16f6`

Returns address of plugin created for given OperaPool



## Functions
### constructor

```solidity
constructor(address _operaFactory) public
```



| Name | Type | Description |
| ---- | ---- | ----------- |
| _operaFactory | address |  |

### beforeCreatePoolHook

```solidity
function beforeCreatePoolHook(address pool, address, address, address, address, bytes) external returns (address)
```
**Selector**: `0x1d0338d9`

Deploys new plugin contract for pool

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | The address of the new pool |
|  | address |  |
|  | address |  |
|  | address |  |
|  | address |  |
|  | bytes |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | New plugin address |

### afterCreatePoolHook

```solidity
function afterCreatePoolHook(address, address, address) external view
```
**Selector**: `0x8d5ef8d1`

Called after the pool is created

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | address |  |
|  | address |  |

### createPluginForExistingPool

```solidity
function createPluginForExistingPool(address token0, address token1) external returns (address)
```
**Selector**: `0x27733026`

Create plugin for already existing pool

| Name | Type | Description |
| ---- | ---- | ----------- |
| token0 | address | The address of first token in pool |
| token1 | address | The address of second token in pool |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of created plugin |

### setDefaultFeeConfiguration

```solidity
function setDefaultFeeConfiguration(struct OperaFeeConfiguration newConfig) external
```
**Selector**: `0xf718949a`

Changes initial fee configuration for new pools

*Developer note: changes coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
alpha1 + alpha2 + baseFee (max possible fee) must be &lt;&#x3D; type(uint16).max and gammas must be &gt; 0*

| Name | Type | Description |
| ---- | ---- | ----------- |
| newConfig | struct OperaFeeConfiguration | new default fee configuration. See the #AdaptiveFee.sol library for details |

### setFarmingAddress

```solidity
function setFarmingAddress(address newFarmingAddress) external
```
**Selector**: `0xb001f618`



*Developer note: updates farmings manager address on the factory*

| Name | Type | Description |
| ---- | ---- | ----------- |
| newFarmingAddress | address | The new tokenomics contract address |

