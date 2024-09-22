

# IOperaPoolPermissionedActions


Permissioned pool actions

Contains pool methods that may only be called by permissioned addresses

*Developer note: Credit to Uniswap Labs under GPL-2.0-or-later license:
https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces*


## Functions
### setCommunityFee

```solidity
function setCommunityFee(uint16 newCommunityFee) external
```
**Selector**: `0x240a875a`

Set the community&#x27;s % share of the fees. Only factory owner or POOLS_ADMINISTRATOR_ROLE role

| Name | Type | Description |
| ---- | ---- | ----------- |
| newCommunityFee | uint16 | The new community fee percent in thousandths (1e-3) |

### setFedReserves

```solidity
function setFedReserves(uint256 _r0, uint256 _r1) external
```
**Selector**: `0x8287d7d0`

Set the new Reserved amounts. Only factory owner or POOLS_ADMINISTRATOR_ROLE role

| Name | Type | Description |
| ---- | ---- | ----------- |
| _r0 | uint256 | The new reserve value |
| _r1 | uint256 | The new reserve value |

### setTickSpacing

```solidity
function setTickSpacing(int24 newTickSpacing) external
```
**Selector**: `0xf085a610`

Set the new tick spacing values. Only factory owner or POOLS_ADMINISTRATOR_ROLE role

| Name | Type | Description |
| ---- | ---- | ----------- |
| newTickSpacing | int24 | The new tick spacing value |

### setPlugin

```solidity
function setPlugin(address newPluginAddress) external
```
**Selector**: `0xcc1f97cf`

Set the new plugin address. Only factory owner or POOLS_ADMINISTRATOR_ROLE role

| Name | Type | Description |
| ---- | ---- | ----------- |
| newPluginAddress | address | The new plugin address |

### setPluginConfig

```solidity
function setPluginConfig(uint8 newConfig) external
```
**Selector**: `0xbca57f81`

Set new plugin config. Only factory owner or POOLS_ADMINISTRATOR_ROLE role

| Name | Type | Description |
| ---- | ---- | ----------- |
| newConfig | uint8 | In the new configuration of the plugin, each bit of which is responsible for a particular hook. |

### setCommunityVault

```solidity
function setCommunityVault(address newCommunityVault) external
```
**Selector**: `0xd8544cf3`

Set new community fee vault address. Only factory owner or POOLS_ADMINISTRATOR_ROLE role

*Developer note: Community fee vault receives collected community fees.
**accumulated but not yet sent to the vault community fees once will be sent to the &#x60;newCommunityVault&#x60; address***

| Name | Type | Description |
| ---- | ---- | ----------- |
| newCommunityVault | address | The address of new community fee vault |

### setFee

```solidity
function setFee(uint16 newFee) external
```
**Selector**: `0x8e005553`

Set new pool fee. Can be called by owner if dynamic fee is disabled.
Called by the plugin if dynamic fee is enabled

| Name | Type | Description |
| ---- | ---- | ----------- |
| newFee | uint16 | The new fee value |

### sync

```solidity
function sync() external
```
**Selector**: `0xfff6cae9`

Forces balances to match reserves. Excessive tokens will be distributed between active LPs

*Developer note: Only plugin can call this function*

### skim

```solidity
function skim() external
```
**Selector**: `0x1dd19cb4`

Forces balances to match reserves. Excessive tokens will be sent to msg.sender

*Developer note: Only plugin can call this function*

