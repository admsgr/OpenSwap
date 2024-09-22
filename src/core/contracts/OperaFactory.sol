// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import './libraries/Constants.sol';

import './interfaces/IOperaFactory.sol';
import './interfaces/IOperaPool.sol';
import './interfaces/IOperaPoolDeployer.sol';
import './interfaces/vault/IOperaVaultFactory.sol';
import './interfaces/plugin/IOperaPluginFactory.sol';

import './OperaCommunityVault.sol';

import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @title Opera factory
/// @notice Is used to deploy pools and its plugins
/// @dev Version: Opera Insider 1.1
contract OperaFactory is IOperaFactory, Ownable2Step, AccessControlEnumerable, ReentrancyGuard {
  /// @inheritdoc IOperaFactory
  bytes32 public constant override POOLS_ADMINISTRATOR_ROLE = keccak256('POOLS_ADMINISTRATOR'); // it`s here for the public visibility of the value

  /// @inheritdoc IOperaFactory
  bytes32 public constant override CUSTOM_POOL_DEPLOYER = keccak256('CUSTOM_POOL_DEPLOYER');

  /// @inheritdoc IOperaFactory
  address public immutable override poolDeployer;

  /// @inheritdoc IOperaFactory
  uint16 public override defaultCommunityFee;

  /// @inheritdoc IOperaFactory
  uint16 public override defaultFee;

  /// @inheritdoc IOperaFactory
  int24 public override defaultTickspacing;

  /// @inheritdoc IOperaFactory
  uint256 public override renounceOwnershipStartTimestamp;

  /// @dev time delay before ownership renouncement can be finished
  uint256 private constant RENOUNCE_OWNERSHIP_DELAY = 1 days;

  /// @inheritdoc IOperaFactory
  IOperaPluginFactory public defaultPluginFactory;

  /// @inheritdoc IOperaFactory
  IOperaVaultFactory public vaultFactory;

  /// @inheritdoc IOperaFactory
  mapping(address => mapping(address => address)) public override poolByPair;

  /// @inheritdoc IOperaFactory
  mapping(address => mapping(address => mapping(address => address))) public override customPoolByPair;

  /// @inheritdoc IOperaFactory
  /// @dev keccak256 of OperaPool init bytecode. Used to compute pool address deterministically
  bytes32 public constant POOL_INIT_CODE_HASH = 0x2bb8d0af67cd2d3bf5e9aebd61e2d8cd496f6944fb524b00b5849c99e4ac67d4;

  constructor(address _poolDeployer) {
    require(_poolDeployer != address(0));
    poolDeployer = _poolDeployer;
    defaultTickspacing = Constants.INIT_DEFAULT_TICK_SPACING;
    defaultFee = Constants.INIT_DEFAULT_FEE;

    emit DefaultTickspacing(Constants.INIT_DEFAULT_TICK_SPACING);
    emit DefaultFee(Constants.INIT_DEFAULT_FEE);
  }

  /// @inheritdoc IOperaFactory
  function owner() public view override(IOperaFactory, Ownable) returns (address) {
    return super.owner();
  }

  /// @inheritdoc IOperaFactory
  function hasRoleOrOwner(bytes32 role, address account) public view override returns (bool) {
    return (owner() == account || super.hasRole(role, account));
  }

  /// @inheritdoc IOperaFactory
  function defaultConfigurationForPool() external view override returns (uint16 communityFee, int24 tickSpacing, uint16 fee) {
    return (defaultCommunityFee, defaultTickspacing, defaultFee);
  }

  /// @inheritdoc IOperaFactory
  function computePoolAddress(address token0, address token1) public view override returns (address pool) {
    pool = address(uint160(uint256(keccak256(abi.encodePacked(hex'ff', poolDeployer, keccak256(abi.encode(token0, token1)), POOL_INIT_CODE_HASH)))));
  }

  /// @inheritdoc IOperaFactory
  function computeCustomPoolAddress(address deployer, address token0, address token1) public view override returns (address customPool) {
    customPool = address(
      uint160(uint256(keccak256(abi.encodePacked(hex'ff', poolDeployer, keccak256(abi.encode(deployer, token0, token1)), POOL_INIT_CODE_HASH))))
    );
  }

  /// @inheritdoc IOperaFactory
  function createPool(address tokenA, address tokenB) external override nonReentrant returns (address pool) {
    return _createPool(address(0), msg.sender, tokenA, tokenB, '');
  }

  /// @inheritdoc IOperaFactory
  function createCustomPool(
    address deployer,
    address creator,
    address tokenA,
    address tokenB,
    bytes calldata data
  ) external override nonReentrant returns (address customPool) {
    require(hasRole(CUSTOM_POOL_DEPLOYER, msg.sender), 'Can`t create custom pools');
    return _createPool(deployer, creator, tokenA, tokenB, data);
  }

  function _createPool(address deployer, address creator, address tokenA, address tokenB, bytes memory data) private returns (address pool) {
    require(tokenA != tokenB);
    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0));

    mapping(address => mapping(address => address)) storage _poolByPair = deployer == address(0) ? poolByPair : customPoolByPair[deployer];
    require(_poolByPair[token0][token1] == address(0));

    address plugin;
    if (deployer == address(0)) {
      if (address(defaultPluginFactory) != address(0)) {
        plugin = defaultPluginFactory.beforeCreatePoolHook(computePoolAddress(token0, token1), creator, address(0), token0, token1, '');
      }
    } else {
      plugin = IOperaPluginFactory(msg.sender).beforeCreatePoolHook(
        computeCustomPoolAddress(deployer, token0, token1),
        creator,
        deployer,
        token0,
        token1,
        data
      );
    }

    pool = IOperaPoolDeployer(poolDeployer).deploy(plugin, token0, token1, deployer);

    if (deployer == address(0)) {
      if (address(defaultPluginFactory) != address(0)) {
        defaultPluginFactory.afterCreatePoolHook(plugin, pool, deployer);
      }
    } else {
      IOperaPluginFactory(msg.sender).afterCreatePoolHook(plugin, pool, deployer);
    }

    _poolByPair[token0][token1] = pool;
    _poolByPair[token1][token0] = pool;

    if (deployer == address(0)) {
      emit Pool(token0, token1, pool);
    } else {
      emit CustomPool(deployer, token0, token1, pool);
    }

    if (address(vaultFactory) != address(0)) {
      address vault = vaultFactory.createVaultForPool(pool, creator, deployer, token0, token1);
      IOperaPool(pool).setCommunityVault(vault);
    }
  }

  /// @inheritdoc IOperaFactory
  function setDefaultCommunityFee(uint16 newDefaultCommunityFee) external override onlyOwner {
    require(newDefaultCommunityFee <= Constants.MAX_COMMUNITY_FEE);
    require(defaultCommunityFee != newDefaultCommunityFee);
    if (newDefaultCommunityFee != 0) require(address(vaultFactory) != address(0));
    defaultCommunityFee = newDefaultCommunityFee;
    emit DefaultCommunityFee(newDefaultCommunityFee);
  }

  /// @inheritdoc IOperaFactory
  function setDefaultFee(uint16 newDefaultFee) external override onlyOwner {
    require(newDefaultFee <= Constants.MAX_DEFAULT_FEE);
    require(defaultFee != newDefaultFee);
    defaultFee = newDefaultFee;
    emit DefaultFee(newDefaultFee);
  }

  /// @inheritdoc IOperaFactory
  function setDefaultTickspacing(int24 newDefaultTickspacing) external override onlyOwner {
    require(newDefaultTickspacing >= Constants.MIN_TICK_SPACING);
    require(newDefaultTickspacing <= Constants.MAX_TICK_SPACING);
    require(newDefaultTickspacing != defaultTickspacing);
    defaultTickspacing = newDefaultTickspacing;
    emit DefaultTickspacing(newDefaultTickspacing);
  }

  /// @inheritdoc IOperaFactory
  function setDefaultPluginFactory(address newDefaultPluginFactory) external override onlyOwner {
    require(newDefaultPluginFactory != address(defaultPluginFactory));
    defaultPluginFactory = IOperaPluginFactory(newDefaultPluginFactory);
    emit DefaultPluginFactory(newDefaultPluginFactory);
  }

  /// @inheritdoc IOperaFactory
  function setVaultFactory(address newVaultFactory) external override onlyOwner {
    require(newVaultFactory != address(vaultFactory));
    if (newVaultFactory == address(0)) require(defaultCommunityFee == 0);
    vaultFactory = IOperaVaultFactory(newVaultFactory);
    emit VaultFactory(newVaultFactory);
  }

  /// @inheritdoc IOperaFactory
  function setThirdPartyAdmin(address _admin) external override onlyOwner {
    require(_admin != address(0));
    _grantRole(POOLS_ADMINISTRATOR_ROLE, _admin);
  }

  /// @inheritdoc IOperaFactory
  function startRenounceOwnership() external override onlyOwner {
    require(renounceOwnershipStartTimestamp == 0);
    renounceOwnershipStartTimestamp = block.timestamp;
    emit RenounceOwnershipStart(renounceOwnershipStartTimestamp, renounceOwnershipStartTimestamp + RENOUNCE_OWNERSHIP_DELAY);
  }

  /// @inheritdoc IOperaFactory
  function stopRenounceOwnership() external override onlyOwner {
    require(renounceOwnershipStartTimestamp != 0);
    renounceOwnershipStartTimestamp = 0;
    emit RenounceOwnershipStop(block.timestamp);
  }

  /// @dev Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore.
  /// Can only be called by the current owner if RENOUNCE_OWNERSHIP_DELAY seconds
  /// have passed since the call to the startRenounceOwnership() function.
  function renounceOwnership() public override onlyOwner {
    require(renounceOwnershipStartTimestamp != 0);
    require(block.timestamp - renounceOwnershipStartTimestamp >= RENOUNCE_OWNERSHIP_DELAY);
    renounceOwnershipStartTimestamp = 0;

    super.renounceOwnership();
    emit RenounceOwnershipFinish(block.timestamp);
  }

  /// @dev Transfers ownership of the contract to a new account (`newOwner`).
  /// Modified to fit with the role mechanism.
  function _transferOwnership(address newOwner) internal override {
    _revokeRole(DEFAULT_ADMIN_ROLE, owner());
    super._transferOwnership(newOwner);
    if (owner() != address(0)) {
      _grantRole(DEFAULT_ADMIN_ROLE, owner());
    }
  }
}
