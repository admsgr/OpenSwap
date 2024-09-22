import { Wallet, getCreateAddress, ZeroAddress } from 'ethers';
import { ethers } from 'hardhat';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { OperaFactory, OperaPoolDeployer, OperaCommunityVault, TestERC20 } from '../typechain';
import { expect } from './shared/expect';

describe('OperaCommunityVault', () => {
  let wallet: Wallet, other: Wallet, third: Wallet;

  let factory: OperaFactory;
  let poolDeployer: OperaPoolDeployer;
  let vault: OperaCommunityVault;

  let token0: TestERC20;
  let token1: TestERC20;

  const AMOUNT = 10n ** 18n;

  const fixture = async () => {
    const [deployer] = await ethers.getSigners();
    // precompute
    const poolDeployerAddress = getCreateAddress({
      from: deployer.address,
      nonce: (await ethers.provider.getTransactionCount(deployer.address)) + 1,
    });

    const factoryFactory = await ethers.getContractFactory('OperaFactory');
    const _factory = (await factoryFactory.deploy(poolDeployerAddress)) as any as OperaFactory;

    const poolDeployerFactory = await ethers.getContractFactory('OperaPoolDeployer');
    poolDeployer = (await poolDeployerFactory.deploy(_factory)) as any as OperaPoolDeployer;

    const vaultFactory = await ethers.getContractFactory('OperaCommunityVault');
    vault = (await vaultFactory.deploy(_factory, deployer.address)) as any as OperaCommunityVault;

    const vaultFactoryStubFactory = await ethers.getContractFactory('OperaVaultFactoryStub');
    const vaultFactoryStub = await vaultFactoryStubFactory.deploy(vault);

    await _factory.setVaultFactory(vaultFactoryStub);

    const tokenFactory = await ethers.getContractFactory('TestERC20');
    token0 = (await tokenFactory.deploy(2n ** 255n)) as any as TestERC20;
    token1 = (await tokenFactory.deploy(2n ** 255n)) as any as TestERC20;

    return _factory;
  };

  before('create fixture loader', async () => {
    [wallet, other, third] = await (ethers as any).getSigners();
  });

  beforeEach('add tokens to vault', async () => {
    factory = await loadFixture(fixture);
    await token0.transfer(vault, AMOUNT);
    await token1.transfer(vault, AMOUNT);
  });

  describe('#Withdraw', async () => {
    describe('successful cases', async () => {
      let communityFeeReceiver: string;

      beforeEach('set communityFee receiver', async () => {
        communityFeeReceiver = wallet.address;
        await vault.changeCommunityFeeReceiver(communityFeeReceiver);

        await vault.transferOperaFeeManagerRole(other.address);
        await vault.connect(other).acceptOperaFeeManagerRole();
      });

      describe('Opera fee off', async () => {
        it('withdraw works', async () => {
          let balanceBefore = await token0.balanceOf(communityFeeReceiver);
          await vault.withdraw(token0, AMOUNT);
          let balanceAfter = await token0.balanceOf(communityFeeReceiver);
          expect(balanceAfter - balanceBefore).to.eq(AMOUNT);
        });

        it('opera fee manager can withdraw', async () => {
          let balanceBefore = await token0.balanceOf(communityFeeReceiver);

          const _vault = vault.connect(third);
          await expect(_vault.withdraw(token0, AMOUNT)).to.be.reverted;

          await _vault.connect(other).withdraw(token0, AMOUNT);

          let balanceAfter = await token0.balanceOf(communityFeeReceiver);
          expect(balanceAfter - balanceBefore).to.eq(AMOUNT);
        });

        it('withdrawTokens works', async () => {
          let balance0Before = await token0.balanceOf(communityFeeReceiver);
          let balance1Before = await token1.balanceOf(communityFeeReceiver);
          await vault.withdrawTokens([
            {
              token: token0,
              amount: AMOUNT,
            },
            {
              token: token1,
              amount: AMOUNT,
            },
          ]);
          let balance0After = await token0.balanceOf(communityFeeReceiver);
          let balance1After = await token1.balanceOf(communityFeeReceiver);
          expect(balance0After - balance0Before).to.eq(AMOUNT);
          expect(balance1After - balance1Before).to.eq(AMOUNT);
        });
      });

      describe('Opera fee on', async () => {
        let operaFeeReceiver: string;
        const OPERA_FEE = 100n; // 10%

        beforeEach('turn on opera fee', async () => {
          operaFeeReceiver = other.address;
          await vault.connect(other).changeOperaFeeReceiver(operaFeeReceiver);

          await vault.connect(other).proposeOperaFeeChange(OPERA_FEE);
          await vault.acceptOperaFeeChangeProposal(OPERA_FEE);
        });

        it('withdraw works', async () => {
          let balanceBefore = await token0.balanceOf(communityFeeReceiver);
          let balanceOperaBefore = await token0.balanceOf(operaFeeReceiver);

          await vault.withdraw(token0, AMOUNT);
          let balanceAfter = await token0.balanceOf(communityFeeReceiver);
          let balanceOperaAfter = await token0.balanceOf(operaFeeReceiver);

          expect(balanceAfter - balanceBefore).to.eq(AMOUNT - (AMOUNT * OPERA_FEE) / 1000n);
          expect(balanceOperaAfter - balanceOperaBefore).to.eq((AMOUNT * OPERA_FEE) / 1000n);
        });

        it('opera fee manager can withdraw', async () => {
          let balanceBefore = await token0.balanceOf(communityFeeReceiver);
          let balanceOperaBefore = await token0.balanceOf(operaFeeReceiver);

          const _vault = vault.connect(third);

          await expect(_vault.withdraw(token0, AMOUNT)).to.be.reverted;

          await _vault.connect(other).withdraw(token0, AMOUNT);

          let balanceAfter = await token0.balanceOf(communityFeeReceiver);
          let balanceOperaAfter = await token0.balanceOf(operaFeeReceiver);

          expect(balanceAfter - balanceBefore).to.eq(AMOUNT - (AMOUNT * OPERA_FEE) / 1000n);
          expect(balanceOperaAfter - balanceOperaBefore).to.eq((AMOUNT * OPERA_FEE) / 1000n);
        });

        it('withdrawTokens works', async () => {
          let balance0Before = await token0.balanceOf(communityFeeReceiver);
          let balance1Before = await token1.balanceOf(communityFeeReceiver);
          let balance0OperaBefore = await token0.balanceOf(operaFeeReceiver);
          let balance1OperaBefore = await token1.balanceOf(operaFeeReceiver);

          await vault.withdrawTokens([
            {
              token: token0,
              amount: AMOUNT,
            },
            {
              token: token1,
              amount: AMOUNT,
            },
          ]);
          let balance0After = await token0.balanceOf(communityFeeReceiver);
          let balance1After = await token1.balanceOf(communityFeeReceiver);
          let balance0OperaAfter = await token0.balanceOf(operaFeeReceiver);
          let balance1OperaAfter = await token1.balanceOf(operaFeeReceiver);

          expect(balance0After - balance0Before).to.eq(AMOUNT - (AMOUNT * OPERA_FEE) / 1000n);
          expect(balance1After - balance1Before).to.eq(AMOUNT - (AMOUNT * OPERA_FEE) / 1000n);
          expect(balance0OperaAfter - balance0OperaBefore).to.eq((AMOUNT * OPERA_FEE) / 1000n);
          expect(balance1OperaAfter - balance1OperaBefore).to.eq((AMOUNT * OPERA_FEE) / 1000n);
        });
      });
    });

    describe('failing cases', async () => {
      it('withdraw onlyWithdrawer', async () => {
        await vault.changeCommunityFeeReceiver(wallet.address);
        expect(await vault.communityFeeReceiver()).to.be.eq(wallet.address);
        await expect(vault.connect(other).withdraw(token0, AMOUNT)).to.be.revertedWith('only withdrawer');
      });

      it('cannot withdraw without communityFeeReceiver', async () => {
        await expect(vault.withdraw(token0, AMOUNT)).to.be.revertedWith('invalid receiver');
      });

      it('withdrawTokens onlyWithdrawer', async () => {
        await vault.changeCommunityFeeReceiver(wallet.address);
        expect(await vault.communityFeeReceiver()).to.be.eq(wallet.address);
        await expect(
          vault.connect(other).withdrawTokens([
            {
              token: token0,
              amount: AMOUNT,
            },
          ])
        ).to.be.reverted;
      });

      it('cannot withdrawTokens without communityFeeReceiver', async () => {
        await expect(
          vault.withdrawTokens([
            {
              token: token0,
              amount: AMOUNT,
            },
          ])
        ).to.be.revertedWith('invalid receiver');
      });

      describe('Opera fee on', async () => {
        const OPERA_FEE = 100n; // 10%

        beforeEach('turn on opera fee', async () => {
          await vault.proposeOperaFeeChange(OPERA_FEE);
          await vault.acceptOperaFeeChangeProposal(OPERA_FEE);
        });

        it('cannot withdraw without operaFeeReceiver', async () => {
          await vault.changeCommunityFeeReceiver(wallet.address);
          expect(await vault.communityFeeReceiver()).to.be.eq(wallet.address);
          await expect(vault.withdraw(token0, AMOUNT)).to.be.revertedWith('invalid opera fee receiver');
        });

        it('cannot withdrawTokens without operaFeeReceiver', async () => {
          await vault.changeCommunityFeeReceiver(wallet.address);
          expect(await vault.communityFeeReceiver()).to.be.eq(wallet.address);
          await expect(
            vault.withdrawTokens([
              {
                token: token0,
                amount: AMOUNT,
              },
            ])
          ).to.be.revertedWith('invalid opera fee receiver');
        });
      });
    });
  });

  describe('#FactoryOwner permissioned actions', async () => {
    const OPERA_FEE = 100n; // 10%

    it('can accept fee change proposal', async () => {
      await vault.proposeOperaFeeChange(OPERA_FEE);
      await vault.acceptOperaFeeChangeProposal(OPERA_FEE);
      expect(await vault.operaFee()).to.be.eq(OPERA_FEE);
      expect(await vault.hasNewOperaFeeProposal()).to.be.eq(false);
    });

    it('only community vault administrator can accept fee change proposal', async () => {
      await vault.proposeOperaFeeChange(OPERA_FEE);
      await expect(vault.connect(other).acceptOperaFeeChangeProposal(OPERA_FEE)).to.be.revertedWith(
        'only administrator'
      );
      await expect(vault.acceptOperaFeeChangeProposal(OPERA_FEE)).to.not.be.reverted;
    });

    it('can not accept invalid fee change proposal', async () => {
      await vault.proposeOperaFeeChange(OPERA_FEE);
      await expect(vault.acceptOperaFeeChangeProposal(OPERA_FEE - 1n)).to.be.revertedWith('invalid new fee');
    });

    it('can not accept fee if nothing proposed', async () => {
      await expect(vault.acceptOperaFeeChangeProposal(OPERA_FEE)).to.be.revertedWith('not proposed');
    });

    it('can change communityFeeReceiver', async () => {
      await vault.changeCommunityFeeReceiver(other.address);
      expect(await vault.communityFeeReceiver()).to.be.eq(other.address);
    });

    it('can not change communityFeeReceiver to zero address', async () => {
      await expect(vault.changeCommunityFeeReceiver(ZeroAddress)).to.be.reverted;
    });

    it('can not change communityFeeReceiver to same address', async () => {
      await vault.changeCommunityFeeReceiver(other.address);
      await expect(vault.changeCommunityFeeReceiver(other.address)).to.be.reverted;
    });

    it('only administrator can change communityFeeReceiver', async () => {
      await expect(vault.connect(other).changeCommunityFeeReceiver(other.address)).to.be.revertedWith(
        'only administrator'
      );
    });
  });

  describe('#OperaFeeManager permissioned actions', async () => {
    const OPERA_FEE = 100n; // 10%

    it('can transfer OperaFeeManager role', async () => {
      await vault.transferOperaFeeManagerRole(other.address);
      await vault.connect(other).acceptOperaFeeManagerRole();
      expect(await vault.operaFeeManager()).to.be.eq(other.address);
    });

    it('only pending newOperaFeeManager can accept OperaFeeManager role', async () => {
      await vault.transferOperaFeeManagerRole(other.address);
      await expect(vault.acceptOperaFeeManagerRole()).to.be.reverted;
      await expect(vault.connect(other).acceptOperaFeeManagerRole()).to.not.be.reverted;
    });

    it('only OperaFeeManager can transfer OperaFeeManager role', async () => {
      await expect(vault.connect(other).transferOperaFeeManagerRole(other.address)).to.be.revertedWith(
        'only opera fee manager'
      );
    });

    it('can change OperaFeeReceiver', async () => {
      await expect(vault.connect(other).changeOperaFeeReceiver(other.address)).to.be.revertedWith(
        'only opera fee manager'
      );
      await expect(vault.changeOperaFeeReceiver(ZeroAddress)).to.be.reverted;

      await vault.changeOperaFeeReceiver(other.address);
      expect(await vault.operaFeeReceiver()).to.be.eq(other.address);
      await expect(vault.changeOperaFeeReceiver(other.address)).to.be.reverted;
    });

    it('can propose new fee and cancel proposal', async () => {
      expect(await vault.proposedNewOperaFee()).to.be.eq(0);
      expect(await vault.hasNewOperaFeeProposal()).to.be.eq(false);

      await expect(vault.connect(other).proposeOperaFeeChange(OPERA_FEE)).to.be.revertedWith(
        'only opera fee manager'
      );
      await expect(vault.proposeOperaFeeChange(1001)).to.be.reverted;

      await vault.proposeOperaFeeChange(OPERA_FEE);
      await expect(vault.proposeOperaFeeChange(OPERA_FEE)).to.be.reverted;
      expect(await vault.proposedNewOperaFee()).to.be.eq(OPERA_FEE);
      expect(await vault.hasNewOperaFeeProposal()).to.be.eq(true);

      await expect(vault.connect(other).cancelOperaFeeChangeProposal()).to.be.revertedWith(
        'only opera fee manager'
      );
      await vault.cancelOperaFeeChangeProposal();

      expect(await vault.proposedNewOperaFee()).to.be.eq(0);
      expect(await vault.hasNewOperaFeeProposal()).to.be.eq(false);

      await vault.proposeOperaFeeChange(OPERA_FEE);
      await vault.acceptOperaFeeChangeProposal(OPERA_FEE);
      await expect(vault.proposeOperaFeeChange(OPERA_FEE)).to.be.reverted;
    });
  });
});
