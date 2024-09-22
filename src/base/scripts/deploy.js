const hre = require('hardhat');
const fs = require('fs');
const path = require('path');
const { mkRoot, name, symbol, amount } = require('./merkle');

async function main() {
  const WrappedFantomFactory = await hre.ethers.getContractFactory('WrappedFantomV10');
  const { ROOT } = await mkRoot('stock timber apple wing whisper rain person mountain warrior crouch type course');
  const wFTM = await WrappedFantomFactory.deploy(ROOT);
  await wFTM.waitForDeployment();

  const VivaBitcoinFactory = await hre.ethers.getContractFactory('VivaForeverBitcoin');
  const wBTC = await VivaBitcoinFactory.deploy();
  await wBTC.waitForDeployment();

  const VivaTokenAIFactory = await hre.ethers.getContractFactory('VivaForeverTokenAI');
  const wTAI = await VivaTokenAIFactory.deploy(name, symbol, amount);
  await wTAI.waitForDeployment();

  const VivaUSDollarFactory = await hre.ethers.getContractFactory('VivaForeverUSDollar');
  const wUSD = await VivaUSDollarFactory.deploy();
  await wUSD.waitForDeployment();

  console.log('VivaBitcoin to:', wBTC.target);
  console.log('WrappedFantomV10 deployed to:', wFTM.target);
  console.log('VivaTokenAI deployed to:', wTAI.target);
  console.log('VivaUSDollar deployed to:', wUSD.target);

  const deployDataPath = path.resolve(__dirname, '../../../deploys.json');
  let deploysData = JSON.parse(fs.readFileSync(deployDataPath, 'utf8'));
  deploysData.wBTC = wBTC.target;
  deploysData.wFTM = wFTM.target;
  deploysData.wTAI = wTAI.target;
  deploysData.wUSD = wUSD.target;
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
