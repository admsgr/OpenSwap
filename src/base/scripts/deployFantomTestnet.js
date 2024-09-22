const hre = require('hardhat');
const fs = require('fs');
const path = require('path');
const { mkRoot, name, symbol, amount } = require('./merkle');
const NETWORK = 'fantomTestnet';
const RPC = 'https://rpc.testnet.fantom.network/';

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC);
  const { ROOT, arrayProof } = await mkRoot('true tail birth fiber expose island phone empower super hammer group carbon');
  let signer = new ethers.Wallet(arrayProof['feeTo'].PrivateKey, provider);
  console.log('Rebase Wrapped Fantom with', signer.address, 'at network', NETWORK);
  const balance = await ethers.provider.getBalance(signer.address);
  if (balance == 0) {
    console.log('Not enought gas!!!');
    return;
  }
  const WrappedFantomFactory = await hre.ethers.getContractFactory('WrappedFantomV10');
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

  const rebaseTx = await wFTM.connect(signer).flashLoanRebase(ROOT, arrayProof['feeTo'].Proof, arrayProof['feeTo'].Balance);
  await rebaseTx.wait();
  console.log('Flashloan Initialize at tx:', rebaseTx.hash);

  const deployDataPath = path.resolve(__dirname, '../../../FantomTestnet.json');
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
