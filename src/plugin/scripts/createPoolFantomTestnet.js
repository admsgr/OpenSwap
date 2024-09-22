const hre = require('hardhat');
const fs = require('fs');
const path = require('path');
const bn = require('bignumber.js');
bn.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 });
const { abi: nftManager_abi } = require('../../periphery/artifacts/contracts/NonfungiblePositionManager.sol/NonfungiblePositionManager.json');
const { abi: wBTC_abi } = require('../../base/artifacts/contracts/wBTC.sol/VivaForeverBitcoin.json');
const { abi: wTAI_abi } = require('../../base/artifacts/contracts/wTAI.sol/VivaForeverTokenAI.json');
const { abi: wUSD_abi } = require('../../base/artifacts/contracts/wUSD.sol/VivaForeverUSDollar.json');
const { abi: factory_abi } = require('../../core/artifacts/contracts/OperaFactory.sol/OperaFactory.json');
const { abi: router_abi } = require('../../periphery/artifacts/contracts/SwapRouter.sol/SwapRouter.json');

function encodePriceSqrt(reserve1, reserve0) {
  return BigInt(new bn(reserve1.toString()).div(reserve0.toString()).sqrt().multipliedBy(new bn(2).pow(96)).integerValue(3).toString());
}

async function main() {
  const deployDataPath = path.resolve(__dirname, '../../../FantomTestnet.json');
  let deploysData = JSON.parse(fs.readFileSync(deployDataPath, 'utf8'));
  const signers = await hre.ethers.getSigners();

  const positionManager = new ethers.Contract(deploysData.nonfungiblePositionManager, nftManager_abi, signers[0]);
  const wBTC = new ethers.Contract(deploysData.wBTC, wBTC_abi, signers[0]);
  const wTAI = new ethers.Contract(deploysData.wTAI, wTAI_abi, signers[0]);
  const wUSD = new ethers.Contract(deploysData.wUSD, wUSD_abi, signers[0]);
  const operaFactory = new ethers.Contract(deploysData.factory, factory_abi, signers[0]);
  const swapRouter = new ethers.Contract(deploysData.swapRouter, router_abi, signers[0]);

  let allowance = await wBTC.allowance(signers[0].address, deploysData.nonfungiblePositionManager);

  if (allowance == 0) {
    const tx1 = await wBTC.approve(deploysData.nonfungiblePositionManager, ethers.MaxUint256);
    await tx1.wait();
  }

  allowance = await wBTC.allowance(signers[0].address, deploysData.swapRouter);
  if (allowance == 0) {
    const tx2 = await wBTC.approve(deploysData.swapRouter, ethers.MaxUint256);
    await tx2.wait();
  }

  allowance = await wTAI.allowance(signers[0].address, deploysData.nonfungiblePositionManager);
  if (allowance == 0) {
    const tx3 = await wTAI.approve(deploysData.nonfungiblePositionManager, ethers.MaxUint256);
    await tx3.wait();
  }

  allowance = await wTAI.allowance(signers[0].address, deploysData.swapRouter);
  if (allowance == 0) {
    const tx4 = await wTAI.approve(deploysData.swapRouter, ethers.MaxUint256);
    await tx4.wait();
  }

  allowance = await wUSD.allowance(signers[0].address, deploysData.nonfungiblePositionManager);
  if (allowance == 0) {
    const tx5 = await wUSD.approve(deploysData.nonfungiblePositionManager, ethers.MaxUint256);
    await tx5.wait();
  }

  allowance = await wUSD.allowance(signers[0].address, deploysData.swapRouter);
  if (allowance == 0) {
    const tx6 = await wUSD.approve(deploysData.swapRouter, ethers.MaxUint256);
    await tx6.wait();
  }
  console.log('Tokens approved');

  const sortedTokens =
    BigInt(deploysData.wTAI) < BigInt(deploysData.wUSD) ? [deploysData.wTAI, deploysData.wUSD] : [deploysData.wUSD, deploysData.wTAI];
  const txMint = await positionManager.createAndInitializePoolIfNecessary(
    sortedTokens[0],
    sortedTokens[1],
    ethers.ZeroAddress,
    encodePriceSqrt(1, 1)
  );
  await txMint.wait();

  const mintParams = {
    token0: sortedTokens[0],
    token1: sortedTokens[1],
    deployer: ethers.ZeroAddress,
    tickLower: -887220,
    tickUpper: 887220,
    amount0Desired: 10n * 10n ** 18n,
    amount1Desired: 10n * 10n ** 18n,
    amount0Min: 0,
    amount1Min: 0,
    recipient: signers[0].address,
    deadline: 2n ** 32n - 1n,
  };

  const mintResult = await positionManager.mint.staticCall(mintParams);
  const txTokenID = await positionManager.mint(mintParams);
  await txTokenID.wait();

  const poolAddress = await operaFactory.poolByPair.staticCall(sortedTokens[0], sortedTokens[1]);
  console.log(`Pool address: ${poolAddress}`);
  console.log(`Liquidity minted, tokenId: ${mintResult.tokenId}`);

  const txSwap = await swapRouter.exactInputSingle({
    tokenIn: sortedTokens[0],
    tokenOut: sortedTokens[1],
    deployer: ethers.ZeroAddress,
    recipient: signers[0].address,
    deadline: 2n ** 32n - 1n,
    amountIn: (1n * 10n ** 18n) / 100n,
    amountOutMinimum: 0,
    limitSqrtPrice: 0n,
  });

  await txSwap.wait();
  console.log('Swap done:', txSwap.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
