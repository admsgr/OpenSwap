const ethers = require('ethers');
const path = require('path');
const fs = require('fs');
const execSync = require('child_process').execSync;
const bn = require('bignumber.js');
bn.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 });

const NETWORK = 'fantomTestnet';
const DEFAULT_HARDHAT_PRIVATE_KEY = '0x94200548ac5b960416dae7c250ebdeb2867695256e53a013b07675ad4024fc44';
const RPC = 'https://rpc.testnet.fantom.network/';

const provider = new ethers.JsonRpcProvider(RPC);
const signer = new ethers.Wallet(DEFAULT_HARDHAT_PRIVATE_KEY, provider);
const devKey = '0x30a591dfed2a7deb71bf8c0321e6152691739a2738dbfccec3e9eddaf5c1d5f2';
const devSigner = new ethers.Wallet(devKey, provider);

function encodePriceSqrt(reserve1, reserve0) {
  return BigInt(new bn(reserve1.toString()).div(reserve0.toString()).sqrt().multipliedBy(new bn(2).pow(96)).integerValue(3).toString());
}

function deployProtocol(network) {
  execSync(`cd src/core && npx hardhat run --network ${network} scripts/deployFantomTestnet.js`, { stdio: 'inherit' });

  execSync(`cd src/plugin && npx hardhat run --network ${network} scripts/deployFantomTestnet.js`, { stdio: 'inherit' });

  execSync(`cd src/periphery && npx hardhat run --network ${network} scripts/deployFantomTestnet.js`, { stdio: 'inherit' });

  execSync(`cd src/farming && npx hardhat run --network ${network} scripts/deployFantomTestnet.js`, { stdio: 'inherit' });
}

function deployBasedTokens(network) {
  execSync(`cd src/base && npx hardhat run --network ${network} scripts/deployFantomTestnet.js`, { stdio: 'inherit' });
}

async function getDeploysData() {
  const deployDataPath = path.resolve(__dirname, '../../FantomTestnet.json');
  return JSON.parse(fs.readFileSync(deployDataPath, 'utf8'));
}

async function approveBasedTokens(deploysData) {
  const { abi: wFTM_abi } = require('../../src/base/artifacts/contracts/wFTM.sol/WrappedFantomV10.json');
  const { abi: wBTC_abi } = require('../../src/base/artifacts/contracts/wBTC.sol/VivaForeverBitcoin.json');
  const { abi: wTAI_abi } = require('../../src/base/artifacts/contracts/wTAI.sol/VivaForeverTokenAI.json');
  const { abi: wUSD_abi } = require('../../src/base/artifacts/contracts/wUSD.sol/VivaForeverUSDollar.json');
  const wFTM = new ethers.Contract(deploysData.wFTM, wFTM_abi, devSigner);
  const wBTC = new ethers.Contract(deploysData.wBTC, wBTC_abi, signer);
  const wTAI = new ethers.Contract(deploysData.wTAI, wTAI_abi, signer);
  const wUSD = new ethers.Contract(deploysData.wUSD, wUSD_abi, signer);

  let allowance = await wBTC.allowance(signer.address, deploysData.nonfungiblePositionManager);

  if (allowance == 0) {
    const tx1 = await wBTC.approve(deploysData.nonfungiblePositionManager, ethers.MaxUint256);
    await tx1.wait();
  }

  allowance = await wBTC.allowance(signer.address, deploysData.swapRouter);
  if (allowance == 0) {
    const tx2 = await wBTC.approve(deploysData.swapRouter, ethers.MaxUint256);
    await tx2.wait();
  }

  allowance = await wTAI.allowance(signer.address, deploysData.nonfungiblePositionManager);
  if (allowance == 0) {
    const tx3 = await wTAI.approve(deploysData.nonfungiblePositionManager, ethers.MaxUint256);
    await tx3.wait();
  }

  allowance = await wTAI.allowance(signer.address, deploysData.swapRouter);
  if (allowance == 0) {
    const tx4 = await wTAI.approve(deploysData.swapRouter, ethers.MaxUint256);
    await tx4.wait();
  }

  allowance = await wUSD.allowance(signer.address, deploysData.nonfungiblePositionManager);
  if (allowance == 0) {
    const tx5 = await wUSD.approve(deploysData.nonfungiblePositionManager, ethers.MaxUint256);
    await tx5.wait();
  }

  allowance = await wUSD.allowance(signer.address, deploysData.swapRouter);
  if (allowance == 0) {
    const tx6 = await wUSD.approve(deploysData.swapRouter, ethers.MaxUint256);
    await tx6.wait();
  }

  allowance = await wFTM.allowance(devSigner.address, deploysData.nonfungiblePositionManager);
  if (allowance == 0) {
    const tx7 = await wFTM.approve(deploysData.nonfungiblePositionManager, ethers.MaxUint256);
    await tx7.wait();
  }

  allowance = await wFTM.allowance(devSigner.address, deploysData.swapRouter);
  if (allowance == 0) {
    const tx8 = await wFTM.approve(deploysData.swapRouter, ethers.MaxUint256);
    await tx8.wait();
  }

  console.log('Tokens approved');
}

async function mintFullRangeLiquidity(deploysData) {
  const { abi: NfTPosManagerAbi } = require('../../src/periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json');
  const positionManager = new ethers.Contract(deploysData.nonfungiblePositionManager, NfTPosManagerAbi, signer);
  const t0 = deploysData.wTAI;
  const t1 = deploysData.wUSD;
  let tx1;

  if (t0 < t1) {
    tx1 = await positionManager.createAndInitializePoolIfNecessary(t0, t1, signer.address, encodePriceSqrt(1, 1));
  } else {
    tx1 = await positionManager.createAndInitializePoolIfNecessary(t1, t0, signer.address, encodePriceSqrt(1, 1));
  }
  await tx1.wait();

  const mintParams = {
    token0: deploysData.wTAI,
    token1: deploysData.wUSD,
    tickLower: -887220,
    tickUpper: 887220,
    amount0Desired: 10n * 10n ** 18n,
    amount1Desired: 10n * 10n ** 18n,
    amount0Min: 0,
    amount1Min: 0,
    recipient: signer.address,
    deadline: 2n ** 32n - 1n,
  };

  const mintResult = await positionManager.mint.staticCall(mintParams);
  const tx2 = await positionManager.mint(mintParams);
  await tx2.wait();

  const { abi: FactoryAbi } = require('../../src/core/artifacts/contracts/OperaFactory.sol/OperaFactory.json');
  const operaFactory = new ethers.Contract(deploysData.factory, FactoryAbi, signer);

  const poolAddress = await operaFactory.poolByPair.staticCall(deploysData.wTAI, deploysData.wUSD);
  console.log(`Pool address: ${poolAddress}`);
  console.log(`Liquidity minted, tokenId: ${mintResult.tokenId}`);

  return poolAddress;
}

async function doSwapZtO(deploysData) {
  const { abi: SwapRouterAbi } = require('../../src/periphery/artifacts/contracts/SwapRouter.sol/SwapRouter.json');
  const swapRouter = new ethers.Contract(deploysData.swapRouter, SwapRouterAbi, signer);

  const tx = await swapRouter.exactInputSingle({
    tokenIn: deploysData.wTAI,
    tokenOut: deploysData.wUSD,
    recipient: signer.address,
    deadline: 2n ** 32n - 1n,
    amountIn: (1n * 10n ** 18n) / 100n,
    amountOutMinimum: 0,
    limitSqrtPrice: 0n,
  });

  await tx.wait();

  console.log('Swap done');
}

async function getPoolFullState(deploysData, poolAddress) {
  const { abi: PoolAbi } = require('../../src/core/artifacts/contracts/OperaPool.sol/OperaPool.json');
  const pool = new ethers.Contract(poolAddress, PoolAbi, signer);

  const ammState = await pool.safelyGetStateOfAMM();

  console.log(`Pool: ${poolAddress}, token0: ${deploysData.wTAI}, token1: ${deploysData.wUSD}`);
  console.log(`Current price: ${ammState.sqrtPrice}`);
  console.log(`Current tick: ${ammState.tick}`);
  console.log(`Current liquidity: ${ammState.activeLiquidity}`);
  console.log(`Last known fee: ${ammState.lastFee}`);
  console.log(`Next active tick: ${ammState.nextTick}`);
  console.log(`Previous active tick: ${ammState.previousTick}`);
}

async function main() {
  deployBasedTokens(NETWORK);
  deployProtocol(NETWORK);

  const deploysData = await getDeploysData();
  await approveBasedTokens(deploysData);
  const poolAddress = await mintFullRangeLiquidity(deploysData);
  await doSwapZtO(deploysData);
  await getPoolFullState(deploysData, poolAddress);
}

main()
  .then(() => {
    console.log('Deploy local finished');
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
