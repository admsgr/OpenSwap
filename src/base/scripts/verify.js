const hre = require('hardhat');
const fs = require('fs');
const path = require('path');
const { makeRoot, name, symbol, amount } = require('./merkle');

async function main() {
  const deployDataPath = path.resolve(__dirname, '../../../FantomTestnet.json');
  let deploysData = JSON.parse(fs.readFileSync(deployDataPath, 'utf8'));

  await run('verify:verify', {
    address: deploysData.nzBTC,
    constructorArguments: [],
  });

  await run('verify:verify', {
    address: deploysData.nzFTM,
    constructorArguments: [(await makeRoot).ROOT],
  });

  await run('verify:verify', {
    address: deploysData.nzTAI,
    constructorArguments: [name, symbol, amount],
  });

  await run('verify:verify', {
    address: deploysData.nzUSD,
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
