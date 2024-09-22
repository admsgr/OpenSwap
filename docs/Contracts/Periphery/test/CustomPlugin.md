

# CustomPlugin






**Inherits:** Timestamp [IOperaPlugin](../../Core/interfaces/plugin/IOperaPlugin.md)

## Public variables
### pool
```solidity
address pool
```
**Selector**: `0x16f0115b`




### OPERA_BASE_PLUGIN_MANAGER
```solidity
bytes32 constant OPERA_BASE_PLUGIN_MANAGER = 0x5959cfd2ad66ed55097b051222324cd6c1dafad3b89e87b9c636df0cc3e5d88b
```
**Selector**: `0xf28e9cae`




### defaultPluginConfig
```solidity
uint8 constant defaultPluginConfig
```
**Selector**: `0x689ea370`

Returns plugin config



## Functions
### beforeInitialize

```solidity
function beforeInitialize(address, uint160) external returns (bytes4)
```
**Selector**: `0x636fd804`



| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | uint160 |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 |  |

### afterInitialize

```solidity
function afterInitialize(address, uint160, int24) external returns (bytes4)
```
**Selector**: `0x82dd6522`



| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | uint160 |  |
|  | int24 |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 |  |

### beforeModifyPosition

```solidity
function beforeModifyPosition(address, address, int24, int24, int128, bytes) external returns (bytes4)
```
**Selector**: `0x5e2411b2`



*Developer note: unused*

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | address |  |
|  | int24 |  |
|  | int24 |  |
|  | int128 |  |
|  | bytes |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 |  |

### afterModifyPosition

```solidity
function afterModifyPosition(address, address, int24, int24, int128, uint256, uint256, bytes) external returns (bytes4)
```
**Selector**: `0xd6852010`



*Developer note: unused*

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | address |  |
|  | int24 |  |
|  | int24 |  |
|  | int128 |  |
|  | uint256 |  |
|  | uint256 |  |
|  | bytes |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 |  |

### beforeSwap

```solidity
function beforeSwap(address, address, bool, int256, uint160, bool, bytes) external returns (bytes4)
```
**Selector**: `0x029c1cb7`



| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | address |  |
|  | bool |  |
|  | int256 |  |
|  | uint160 |  |
|  | bool |  |
|  | bytes |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 |  |

### afterSwap

```solidity
function afterSwap(address, address, bool, int256, uint160, int256, int256, bytes) external returns (bytes4)
```
**Selector**: `0x9cb5a963`



| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | address |  |
|  | bool |  |
|  | int256 |  |
|  | uint160 |  |
|  | int256 |  |
|  | int256 |  |
|  | bytes |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 |  |

### beforeFlash

```solidity
function beforeFlash(address, address, uint256, uint256, bytes) external returns (bytes4)
```
**Selector**: `0x8de0a8ee`



*Developer note: unused*

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | address |  |
|  | uint256 |  |
|  | uint256 |  |
|  | bytes |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 |  |

### afterFlash

```solidity
function afterFlash(address, address, uint256, uint256, uint256, uint256, bytes) external returns (bytes4)
```
**Selector**: `0x343d37ff`



*Developer note: unused*

| Name | Type | Description |
| ---- | ---- | ----------- |
|  | address |  |
|  | address |  |
|  | uint256 |  |
|  | uint256 |  |
|  | uint256 |  |
|  | uint256 |  |
|  | bytes |  |

**Returns:**

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes4 |  |

