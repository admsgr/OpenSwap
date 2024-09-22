import { ethers } from 'hardhat';
import { getCreateAddress } from 'ethers';
import {
  MockTimeOperaPool,
  TestERC20,
  OperaFactory,
  OperaCommunityVault,
  TestOperaCallee,
  TestOperaRouter,
  MockTimeOperaPoolDeployer,
  OperaPoolDeployer,
} from '../../typechain';

type Fixture<T> = () => Promise<T>;
interface FactoryFixture {
  factory: OperaFactory;
  vault: OperaCommunityVault;
}
export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

async function factoryFixture(): Promise<FactoryFixture> {
  const [deployer] = await ethers.getSigners();
  // precompute
  const poolDeployerAddress = getCreateAddress({
    from: deployer.address,
    nonce: (await ethers.provider.getTransactionCount(deployer.address)) + 1,
  });

  const factoryFactory = await ethers.getContractFactory('OperaFactory');
  const factory = (await factoryFactory.deploy(poolDeployerAddress)) as any as OperaFactory;

  const poolDeployerFactory = await ethers.getContractFactory('OperaPoolDeployer');
  const poolDeployer = (await poolDeployerFactory.deploy(factory)) as any as OperaPoolDeployer;

  const vaultFactory = await ethers.getContractFactory('OperaCommunityVault');
  const vault = (await vaultFactory.deploy(factory, deployer.address)) as any as OperaCommunityVault;

  const vaultFactoryStubFactory = await ethers.getContractFactory('OperaVaultFactoryStub');
  const vaultFactoryStub = await vaultFactoryStubFactory.deploy(vault);

  await factory.setVaultFactory(vaultFactoryStub);
  return { factory, vault };
}
interface TokensFixture {
  token0: TestERC20;
  token1: TestERC20;
  token2: TestERC20;
}

async function tokensFixture(): Promise<TokensFixture> {
  const tokenFactory = await ethers.getContractFactory('TestERC20');
  const tokenA = (await tokenFactory.deploy(2n ** 255n)) as any as TestERC20 & { address_: string };
  const tokenB = (await tokenFactory.deploy(2n ** 255n)) as any as TestERC20 & { address_: string };
  const tokenC = (await tokenFactory.deploy(2n ** 255n)) as any as TestERC20 & { address_: string };

  tokenA.address_ = await tokenA.getAddress();
  tokenB.address_ = await tokenB.getAddress();
  tokenC.address_ = await tokenC.getAddress();

  const [token0, token1, token2] = [tokenA, tokenB, tokenC].sort((tokenA, tokenB) =>
    tokenA.address_.toLowerCase() < tokenB.address_.toLowerCase() ? -1 : 1
  );

  return { token0, token1, token2 };
}

type TokensAndFactoryFixture = FactoryFixture & TokensFixture;

interface PoolFixture extends TokensAndFactoryFixture {
  swapTargetCallee: TestOperaCallee;
  swapTargetRouter: TestOperaRouter;
  createPool(firstToken?: TestERC20, secondToken?: TestERC20): Promise<MockTimeOperaPool>;
}

// Monday, October 5, 2020 9:00:00 AM GMT-05:00
export const TEST_POOL_START_TIME = 1601906400;
export const TEST_POOL_DAY_BEFORE_START = 1601906400 - 24 * 60 * 60;

export const poolFixture: Fixture<PoolFixture> = async function (): Promise<PoolFixture> {
  const { factory, vault } = await factoryFixture();
  const { token0, token1, token2 } = await tokensFixture();
  //const { dataStorage } = await dataStorageFixture();

  const MockTimeOperaPoolDeployerFactory = await ethers.getContractFactory('MockTimeOperaPoolDeployer');
  const MockTimeOperaPoolFactory = await ethers.getContractFactory('MockTimeOperaPool');

  const calleeContractFactory = await ethers.getContractFactory('TestOperaCallee');
  const routerContractFactory = await ethers.getContractFactory('TestOperaRouter');

  const swapTargetCallee = (await calleeContractFactory.deploy()) as any as TestOperaCallee;
  const swapTargetRouter = (await routerContractFactory.deploy()) as any as TestOperaRouter;

  return {
    token0,
    token1,
    token2,
    factory,
    vault,
    swapTargetCallee,
    swapTargetRouter,
    createPool: async (firstToken = token0, secondToken = token1) => {
      const mockTimePoolDeployer =
        (await MockTimeOperaPoolDeployerFactory.deploy()) as any as MockTimeOperaPoolDeployer;

      const ADMIN_ROLE = await factory.POOLS_ADMINISTRATOR_ROLE();
      await factory.grantRole(ADMIN_ROLE, mockTimePoolDeployer);

      await mockTimePoolDeployer.deployMock(factory, firstToken, secondToken);

      const firstAddress = await firstToken.getAddress();
      const secondAddress = await secondToken.getAddress();
      const sortedTokens =
        BigInt(firstAddress) < BigInt(secondAddress) ? [firstAddress, secondAddress] : [secondAddress, firstAddress];
      const poolAddress = await mockTimePoolDeployer.computeAddress(sortedTokens[0], sortedTokens[1]);
      return MockTimeOperaPoolFactory.attach(poolAddress) as any as MockTimeOperaPool;
    },
  };
};
