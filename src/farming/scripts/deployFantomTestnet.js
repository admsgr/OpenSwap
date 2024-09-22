const hre = require('hardhat');
const fs = require('fs');
const path = require('path');
const BasePluginV1FactoryComplied = require('@openswap/opera-insider-base-plugin/artifacts/contracts/BasePluginV1Factory.sol/BasePluginV1Factory.json');

async function main() {
  const deployDataPath = path.resolve(__dirname, '../../../FantomTestnet.json');
  const deploysData = JSON.parse(fs.readFileSync(deployDataPath, 'utf8'));

  const OperaEternalFarmingFactory = await hre.ethers.getContractFactory('OperaEternalFarming');
  const OperaEternalFarming = await OperaEternalFarmingFactory.deploy(deploysData.poolDeployer, deploysData.nonfungiblePositionManager);

  deploysData.eternal = OperaEternalFarming.target;

  await OperaEternalFarming.waitForDeployment();
  console.log('OperaEternalFarming deployed to:', OperaEternalFarming.target);

  const FarmingCenterFactory = await hre.ethers.getContractFactory('FarmingCenter');
  const FarmingCenter = await FarmingCenterFactory.deploy(OperaEternalFarming.target, deploysData.nonfungiblePositionManager);

  deploysData.fc = FarmingCenter.target;

  await FarmingCenter.waitForDeployment();
  console.log('FarmingCenter deployed to:', FarmingCenter.target);

  await (await OperaEternalFarming.setFarmingCenterAddress(FarmingCenter.target)).wait();
  console.log('Updated farming center address in eternal(incentive) farming');

  const pluginFactory = await hre.ethers.getContractAt(BasePluginV1FactoryComplied.abi, deploysData.BasePluginV1Factory);

  await (await pluginFactory.setFarmingAddress(FarmingCenter.target)).wait();
  console.log('Updated farming center address in plugin factory');

  const posManager = await hre.ethers.getContractAt('INonfungiblePositionManager', deploysData.nonfungiblePositionManager);
  await (await posManager.setFarmingCenter(FarmingCenter.target)).wait();

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
