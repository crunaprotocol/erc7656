require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const fs = require("fs-extra");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;
const canonicalBytecodes = require("./canonicalBytecodes.json");

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  let deployer;
  const chainId = await deployUtils.currentChainId();
  const isLocalhost = chainId === 1337;
  [deployer] = await ethers.getSigners();

  const bytecodesPath = path.resolve(
      __dirname,
      "canonicalBytecodes.json",
  );

  const bytecodes = JSON.parse(fs.readFileSync(bytecodesPath, "utf8"));

  if (isLocalhost) {
    // on localhost, we deploy the factory if not deployed yet
    await deployUtils.deployNickSFactory(deployer);
    // we also deploy the ERC6551Registry if not deployed yet
  }

  await deployUtils.deployBytecodeViaNickSFactory(
    deployer,
    "ERC7656Registry",
    bytecodes.bytecode,
    bytecodes.salt,
  );

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
