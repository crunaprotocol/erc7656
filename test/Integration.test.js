const { expect } = require("chai");
const { ethers } = require("hardhat");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();
const bytecodes = require("../contracts/bytecode.json");

const {
  cl,
  amount,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  getInterfaceId,
  deployRegistry
} = require("./helpers");

describe("Integration test", function () {
  let registry;

  let deployer, bob, alice, fred, mark;
  let chainId, ts;


  before(async function () {
    [deployer, bob, alice, fred, mark] = await ethers.getSigners();
    await deployUtils.deployNickSFactory(deployer);

    chainId = await getChainId();
    let registry = await deployUtils.deployBytecodeViaNickSFactory(
        deployer,
        "ERC7656Registry",
        bytecodes.bytecode,
        bytecodes.salt,
    );
    const registryAddress = await registry.getAddress();
    expect(registryAddress).equal(bytecodes.address);
    expect(await getInterfaceId("IERC7656Registry")).equal("c6bdc908");
    expect(await getInterfaceId("IERC7656Service")).equal("fc0c546a");

  });

  it("should deploy everything as expected", async function () {});

});
