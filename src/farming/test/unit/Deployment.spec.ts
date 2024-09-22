import { ethers } from 'hardhat';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { OperaEternalFarming } from '../../typechain';
import { operaFixture, OperaFixtureType } from '../shared/fixtures';
import { expect } from '../shared';

describe('unit/Deployment', () => {
  let context: OperaFixtureType;

  beforeEach('create fixture loader', async () => {
    context = await loadFixture(operaFixture);
  });

  it('deploys and has an address', async () => {
    const farmingFactory = await ethers.getContractFactory('OperaEternalFarming');
    const farming = (await farmingFactory.deploy(context.deployer, context.nft)) as any as OperaEternalFarming;
    expect(await farming.getAddress()).to.be.a.string;
  });

  it('sets immutable variables', async () => {
    const farmingFactory = await ethers.getContractFactory('OperaEternalFarming');
    const farming = (await farmingFactory.deploy(context.deployer, context.nft)) as any as OperaEternalFarming;

    expect(await farming.nonfungiblePositionManager()).to.equal(await context.nft.getAddress());
  });
});
