import {
  abi as FACTORY_ABI,
  bytecode as FACTORY_BYTECODE,
} from '@openswap/opera-insider-core/artifacts/contracts/OperaFactory.sol/OperaFactory.json';
import {
  abi as TEST_CALLEE_ABI,
  bytecode as TEST_CALLEE_BYTECODE,
} from '@openswap/opera-insider-core/artifacts/contracts/test/TestOperaCallee.sol/TestOperaCallee.json';
import {
  abi as POOL_DEPLOYER_ABI,
  bytecode as POOL_DEPLOYER_BYTECODE,
} from '@openswap/opera-insider-core/artifacts/contracts/test/MockTimeOperaPoolDeployer.sol/MockTimeOperaPoolDeployer.json';
import {
  abi as POOL_ABI,
  bytecode as POOL_BYTECODE,
} from '@openswap/opera-insider-core/artifacts/contracts/test/MockTimeOperaPool.sol/MockTimeOperaPool.json';
import {
  abi as COM_VAULT_DEPLOYER_ABI,
  bytecode as COM_VAULT_DEPLOYER_BYTECODE,
} from '@openswap/opera-insider-core/artifacts/contracts/OperaCommunityVault.sol/OperaCommunityVault.json';
import {
  abi as COM_VAULT_STUB_DEPLOYER_ABI,
  bytecode as COM_VAULT_STUB_DEPLOYER_BYTECODE,
} from '@openswap/opera-insider-core/artifacts/contracts/OperaVaultFactoryStub.sol/OperaVaultFactoryStub.json';

import { ethers } from 'hardhat';
import {
  MockTimeOperaPoolDeployer,
  OperaCommunityVault,
  TestOperaCallee,
  MockTimeOperaPool,
  OperaFactory,
  TestERC20,
} from '@openswap/opera-insider-core/typechain';
import { getCreateAddress } from 'ethers';
import { ZERO_ADDRESS } from './fixtures';

interface TokensFixture {
  token0: TestERC20;
  token1: TestERC20;
}

export async function tokensFixture(): Promise<TokensFixture> {
  const tokenFactory = await ethers.getContractFactory('TestERC20');
  const tokenA = (await tokenFactory.deploy(2n ** 255n)) as any as TestERC20 & { address: string };
  const tokenB = (await tokenFactory.deploy(2n ** 255n)) as any as TestERC20 & { address: string };

  tokenA.address = await tokenA.getAddress();
  tokenB.address = await tokenB.getAddress();

  const [token0, token1] = [tokenA, tokenB].sort((_tokenA, _tokenB) => (_tokenA.address.toLowerCase() < _tokenB.address.toLowerCase() ? -1 : 1));

  return { token0, token1 };
}

interface MockPoolDeployerFixture extends TokensFixture {
  poolDeployer: MockTimeOperaPoolDeployer;
  swapTargetCallee: TestOperaCallee;
  factory: OperaFactory;
  createPool(firstToken?: TestERC20, secondToken?: TestERC20): Promise<MockTimeOperaPool>;
}
export const operaPoolDeployerMockFixture: () => Promise<MockPoolDeployerFixture> = async () => {
  const { token0, token1 } = await tokensFixture();

  const [deployer] = await ethers.getSigners();
  // precompute
  const poolDeployerAddress = getCreateAddress({
    from: deployer.address,
    nonce: (await ethers.provider.getTransactionCount(deployer.address)) + 1,
  });

  const factoryFactory = await ethers.getContractFactory(FACTORY_ABI, FACTORY_BYTECODE);
  const factory = (await factoryFactory.deploy(poolDeployerAddress)) as any as OperaFactory;

  const poolDeployerFactory = await ethers.getContractFactory(POOL_DEPLOYER_ABI, POOL_DEPLOYER_BYTECODE);
  const poolDeployer = (await poolDeployerFactory.deploy()) as any as MockTimeOperaPoolDeployer;

  const ADMIN_ROLE = await factory.POOLS_ADMINISTRATOR_ROLE();
  await factory.grantRole(ADMIN_ROLE, poolDeployer);

  const vaultFactory = await ethers.getContractFactory(COM_VAULT_DEPLOYER_ABI, COM_VAULT_DEPLOYER_BYTECODE);
  const vault = (await vaultFactory.deploy(factory, deployer.address)) as any as OperaCommunityVault;

  const vaultFactoryStubFactory = await ethers.getContractFactory(COM_VAULT_STUB_DEPLOYER_ABI, COM_VAULT_STUB_DEPLOYER_BYTECODE);
  const vaultFactoryStub = await vaultFactoryStubFactory.deploy(vault);

  await factory.setVaultFactory(vaultFactoryStub);

  const calleeContractFactory = await ethers.getContractFactory(TEST_CALLEE_ABI, TEST_CALLEE_BYTECODE);
  const swapTargetCallee = (await calleeContractFactory.deploy()) as any as TestOperaCallee;

  const MockTimeOperaPoolFactory = await ethers.getContractFactory(POOL_ABI, POOL_BYTECODE);

  return {
    poolDeployer,
    swapTargetCallee,
    token0,
    token1,
    factory,
    createPool: async (firstToken = token0, secondToken = token1) => {
      await poolDeployer.deployMock(factory, firstToken, secondToken);

      const sortedTokens =
        BigInt(await firstToken.getAddress()) < BigInt(await secondToken.getAddress())
          ? [await firstToken.getAddress(), await secondToken.getAddress()]
          : [await secondToken.getAddress(), await firstToken.getAddress()];
      const poolAddress = await poolDeployer.computeAddress(sortedTokens[0], sortedTokens[1]);
      return MockTimeOperaPoolFactory.attach(poolAddress) as any as MockTimeOperaPool;
    },
  };
};
