const hre = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  const deployDataPath = path.resolve(__dirname, '../../../FantomTestnet.json');
  let deploysData = JSON.parse(fs.readFileSync(deployDataPath, 'utf8'));
  const [deployer] = await hre.ethers.getSigners();
  // precompute
  const poolDeployerAddress = hre.ethers.getCreateAddress({
    from: deployer.address,
    nonce: (await ethers.provider.getTransactionCount(deployer.address)) + 1,
  });

  const OperaFactory = await hre.ethers.getContractFactory('OperaFactory');
  const factory = await OperaFactory.deploy(poolDeployerAddress);

  await factory.waitForDeployment();

  const PoolDeployerFactory = await hre.ethers.getContractFactory('OperaPoolDeployer');
  const poolDeployer = await PoolDeployerFactory.deploy(factory.target);

  await poolDeployer.waitForDeployment();

  console.log('OperaPoolDeployer to:', poolDeployer.target);
  console.log('OperaFactory deployed to:', factory.target);

  const vaultFactory = await hre.ethers.getContractFactory('OperaCommunityVault');
  const vault = await vaultFactory.deploy(factory, deployer.address);

  await vault.waitForDeployment();

  console.log('OperaCommunityVault deployed to:', vault.target);

  const vaultFactoryStubFactory = await hre.ethers.getContractFactory('OperaVaultFactoryStub');
  const vaultFactoryStub = await vaultFactoryStubFactory.deploy(vault);

  await vaultFactoryStub.waitForDeployment();

  console.log('OperaVaultFactoryStub deployed to:', vaultFactoryStub.target);

  const setVaultTx = await factory.setVaultFactory(vaultFactoryStub);
  await setVaultTx.wait();

  // protocol fee settings
  const operaFeeRecipient = '0x74680987157c90C5975351e0503c35925bf08436';
  const partnerAddress = '0xc9fdC11A4D29d223C5B36fbbfC147112E75e4222'; // owner address, must be changed
  const operaFeeShare = 1000; // specified on operaVault, 100% of community fee by default(3% of all fees)
  const defaultCommunityFee = 30; // 3% by default

  const setCommunityFeeTx = await factory.setDefaultCommunityFee(defaultCommunityFee);
  await setCommunityFeeTx.wait();

  const changeOperaFeeReceiverTx = await vault.changeOperaFeeReceiver(operaFeeRecipient);
  await changeOperaFeeReceiverTx.wait();

  const changePartnerFeeReceiverTx = await vault.changeCommunityFeeReceiver(partnerAddress);
  await changePartnerFeeReceiverTx.wait();

  await (await vault.proposeOperaFeeChange(operaFeeShare)).wait();
  await (await vault.acceptOperaFeeChangeProposal(operaFeeShare)).wait();

  await (await factory.transferOwnership(partnerAddress)).wait();

  deploysData.poolDeployer = poolDeployer.target;
  deploysData.factory = factory.target;
  deploysData.vault = vault.target;
  deploysData.vaultFactory = vaultFactoryStub.target;
  fs.writeFileSync(deployDataPath, JSON.stringify(deploysData), 'utf-8');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
