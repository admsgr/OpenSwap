

# IOperaCommunityVault


The interface for the Opera community fee vault

Community fee from pools is sent here, if it is enabled

*Developer note: Version: Opera Insider*


## Events
### TokensWithdrawal

```solidity
event TokensWithdrawal(address token, address to, uint256 amount)
```

Event emitted when a fees has been claimed

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The address of token fee |
| to | address | The address where claimed rewards were sent to |
| amount | uint256 | The amount of fees tokens claimed by communityFeeReceiver |

### OperaTokensWithdrawal

```solidity
event OperaTokensWithdrawal(address token, address to, uint256 amount)
```

Event emitted when a fees has been claimed

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The address of token fee |
| to | address | The address where claimed rewards were sent to |
| amount | uint256 | The amount of fees tokens claimed by Opera |

### OperaFeeReceiver

```solidity
event OperaFeeReceiver(address newOperaFeeReceiver)
```

Emitted when a OperaFeeReceiver address changed

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOperaFeeReceiver | address | New Opera fee receiver address |

### PendingOperaFeeManager

```solidity
event PendingOperaFeeManager(address pendingOperaFeeManager)
```

Emitted when a OperaFeeManager address change proposed

| Name | Type | Description |
| ---- | ---- | ----------- |
| pendingOperaFeeManager | address | New pending Opera fee manager address |

### OperaFeeProposal

```solidity
event OperaFeeProposal(uint16 proposedNewOperaFee)
```

Emitted when a new Opera fee value proposed

| Name | Type | Description |
| ---- | ---- | ----------- |
| proposedNewOperaFee | uint16 | The new proposed Opera fee value |

### CancelOperaFeeProposal

```solidity
event CancelOperaFeeProposal()
```

Emitted when a Opera fee proposal canceled

### OperaFeeManager

```solidity
event OperaFeeManager(address newOperaFeeManager)
```

Emitted when a OperaFeeManager address changed

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOperaFeeManager | address | New Opera fee manager address |

### OperaFee

```solidity
event OperaFee(uint16 newOperaFee)
```

Emitted when the Opera fee is changed

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOperaFee | uint16 | The new Opera fee value |

### CommunityFeeReceiver

```solidity
event CommunityFeeReceiver(address newCommunityFeeReceiver)
```

Emitted when a CommunityFeeReceiver address changed

| Name | Type | Description |
| ---- | ---- | ----------- |
| newCommunityFeeReceiver | address | New fee receiver address |


## Structs
### WithdrawTokensParams



```solidity
struct WithdrawTokensParams {
  address token;
  uint256 amount;
}
```


## Functions
### withdraw

```solidity
function withdraw(address token, uint256 amount) external
```
**Selector**: `0xf3fef3a3`

Withdraw protocol fees from vault

*Developer note: Can only be called by operaFeeManager or communityFeeReceiver*

| Name | Type | Description |
| ---- | ---- | ----------- |
| token | address | The token address |
| amount | uint256 | The amount of token |

### withdrawTokens

```solidity
function withdrawTokens(struct IOperaCommunityVault.WithdrawTokensParams[] params) external
```
**Selector**: `0xdfadc794`

Withdraw protocol fees from vault. Used to claim fees for multiple tokens

*Developer note: Can be called by operaFeeManager or communityFeeReceiver*

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IOperaCommunityVault.WithdrawTokensParams[] | Array of WithdrawTokensParams objects containing token addresses and amounts to withdraw |

### acceptOperaFeeChangeProposal

```solidity
function acceptOperaFeeChangeProposal(uint16 newOperaFee) external
```
**Selector**: `0xff3c43e1`

Accepts the proposed new Opera fee

*Developer note: Can only be called by the factory owner.
The new value will also be used for previously accumulated tokens that have not yet been withdrawn*

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOperaFee | uint16 | New Opera fee value |

### changeCommunityFeeReceiver

```solidity
function changeCommunityFeeReceiver(address newCommunityFeeReceiver) external
```
**Selector**: `0xb5f680ae`

Change community fee receiver address

*Developer note: Can only be called by the factory owner*

| Name | Type | Description |
| ---- | ---- | ----------- |
| newCommunityFeeReceiver | address | New community fee receiver address |

### transferOperaFeeManagerRole

```solidity
function transferOperaFeeManagerRole(address _newOperaFeeManager) external
```
**Selector**: `0x50eea0c8`

Transfers Opera fee manager role

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newOperaFeeManager | address | new Opera fee manager address |

### acceptOperaFeeManagerRole

```solidity
function acceptOperaFeeManagerRole() external
```
**Selector**: `0xad6129ac`

accept Opera FeeManager role

### proposeOperaFeeChange

```solidity
function proposeOperaFeeChange(uint16 newOperaFee) external
```
**Selector**: `0xd9fb4353`

Proposes new Opera fee value for protocol

*Developer note: the new value will also be used for previously accumulated tokens that have not yet been withdrawn*

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOperaFee | uint16 | new Opera fee value |

### cancelOperaFeeChangeProposal

```solidity
function cancelOperaFeeChangeProposal() external
```
**Selector**: `0xd17bc783`

Cancels Opera fee change proposal

### changeOperaFeeReceiver

```solidity
function changeOperaFeeReceiver(address newOperaFeeReceiver) external
```
**Selector**: `0x48a50fcf`

Change Opera community fee part receiver

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOperaFeeReceiver | address | The address of new Opera fee receiver |

