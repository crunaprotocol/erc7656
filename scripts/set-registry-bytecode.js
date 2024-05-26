require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const fs = require("fs-extra");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  const bytecodesPath = path.resolve(
      __dirname,
      "../contracts/bytecode.json",
  );

  let bytecodes;
  if (fs.existsSync(bytecodesPath)) {
    bytecodes = JSON.parse(fs.readFileSync(bytecodesPath, "utf8"));
  } else {
    bytecodes = {};
  }

  let salt = bytecodes.salt || ethers.constants.HashZero;
  bytecodes.salt = salt;

  bytecodes.bytecode = await deployUtils.getBytecodeToBeDeployedViaNickSFactory("ERC7656Registry");

  bytecodes.address = await deployUtils.getAddressOfContractDeployedWithBytecodeViaNickSFactory(
    bytecodes.bytecode,
    salt,
  );

  fs.writeFileSync(bytecodesPath, JSON.stringify(bytecodes, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
