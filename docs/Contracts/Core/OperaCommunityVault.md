

# OperaCommunityVault


Opera community fee vault

Community fee from pools is sent here, if it is enabled

*Developer note: Role system is used to withdraw tokens
Version: Opera Insider 1.1*

**Inherits:** [IOperaCommunityVault](interfaces/vault/IOperaCommunityVault.md)
## Modifiers
### onlyAdministrator

```solidity
modifier onlyAdministrator()
```



### onlyWithdrawer

```solidity
modifier onlyWithdrawer()
```



### onlyOperaFeeManager

```solidity
modifier onlyOperaFeeManager()
```




## Public variables
### COMMUNITY_FEE_WITHDRAWER_ROLE
```solidity
bytes32 constant COMMUNITY_FEE_WITHDRAWER_ROLE = 0xb77a63f119f4dc2174dc6c76fc1a1565fa4f2b0dde50ed5c0465471cd9b331f6
```
**Selector**: `0x1de41613`



*Developer note: The role can be granted in OperaFactory*

### COMMUNITY_FEE_VAULT_ADMINISTRATOR
```solidity
bytes32 constant COMMUNITY_FEE_VAULT_ADMINISTRATOR = 0x63e58c34d94475ba3fc063e19800b940485850d84d09cd3c1f2c14192c559a68
```
**Selector**: `0xbbac3b8d`



*Developer note: The role can be granted in OperaFactory*

### communityFeeReceiver
```solidity
address communityFeeReceiver
```
**Selector**: `0x371abc95`

Address to which community fees are sent from vault


### operaFee
```solidity
uint16 operaFee
```
**Selector**: `0x4693e72a`

The percentage of the protocol fee that Opera will receive

*Developer note: Value in thousandths,i.e. 1e-3*

### hasNewOperaFeeProposal
```solidity
bool hasNewOperaFeeProposal
```
**Selector**: `0x8ab3d9de`

Represents whether there is a new Opera fee proposal or not


### proposedNewOperaFee
```solidity
uint16 proposedNewOperaFee
```
**Selector**: `0xdb1bd4b8`

Suggested Opera fee value


### operaFeeReceiver
```solidity
address operaFeeReceiver
```
**Selector**: `0x992b73bd`

Address of recipient Opera part of community fee


### operaFeeManager
```solidity
address operaFeeManager
```
**Selector**: `0xaeddd3f7`

Address of Opera fee manager



## Functions
### constructor

```solidity
constructor(address _factory, address _operaFeeManager) public
```



| Name | Type | Description |
| ---- | ---- | ----------- |
| _factory | address |  |
| _operaFeeManager | address |  |

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
**Selector**: `0x350d2b3e`

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
**Selector**: `0xc18a25b4`

Transfers Opera fee manager role

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newOperaFeeManager | address | new Opera fee manager address |

### acceptOperaFeeManagerRole

```solidity
function acceptOperaFeeManagerRole() external
```
**Selector**: `0x57adc9cb`

accept Opera FeeManager role

### proposeOperaFeeChange

```solidity
function proposeOperaFeeChange(uint16 newOperaFee) external
```
**Selector**: `0x318a953c`

Proposes new Opera fee value for protocol

*Developer note: the new value will also be used for previously accumulated tokens that have not yet been withdrawn*

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOperaFee | uint16 | new Opera fee value |

### cancelOperaFeeChangeProposal

```solidity
function cancelOperaFeeChangeProposal() external
```
**Selector**: `0x8b842f3a`

Cancels Opera fee change proposal

### changeOperaFeeReceiver

```solidity
function changeOperaFeeReceiver(address newOperaFeeReceiver) external
```
**Selector**: `0xe0281976`

Change Opera community fee part receiver

| Name | Type | Description |
| ---- | ---- | ----------- |
| newOperaFeeReceiver | address | The address of new Opera fee receiver |

