require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const fs = require("fs-extra");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  let deployer;
  const chainId = await deployUtils.currentChainId();
  [deployer] = await ethers.getSigners();

  const bytecodesPath = path.resolve(
      __dirname,
      "../contracts/bytecode.json",
  );

  const bytecodes = JSON.parse(fs.readFileSync(bytecodesPath, "utf8"));

  console.log(
    "The code for registry has changed:",
    bytecodes.bytecode !==
      (await deployUtils.getBytecodeToBeDeployedViaNickSFactory("ERC7656Service.sol")),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
