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

describe("Integration test", async function () {
  let registry;
  let deployer, bob, alice, fred, mark;
  let chainId, ts;
  let guardian, service, upgradeableService, upgradeableServiceProxy, nft;
  const salt0 = "0x"+ "0".repeat(64);


  before(async function () {
    [deployer, bob, alice, fred, mark] = await ethers.getSigners();
    await deployUtils.deployNickSFactory(deployer);

    chainId = await getChainId();
    registry = await deployUtils.deployBytecodeViaNickSFactory(
        deployer,
        "ERC7656Registry",
        bytecodes.bytecode,
        bytecodes.salt,
    );
    const registryAddress = await registry.getAddress();
    expect(registryAddress).equal(bytecodes.address);
    expect(await getInterfaceId("IERC7656Registry")).equal("c6bdc908");
    expect(await getInterfaceId("IERC7656Service")).equal("fc0c546a");

    const guardianArtifact = require("../artifacts/contracts/mocks/Guardian.sol/Guardian.json");

    guardian = await deployUtils.deployBytecodeViaNickSFactory(
        deployer,
        "Guardian",
        guardianArtifact.bytecode,
        salt0,
    );

    expect(await guardian.getAddress()).equal("0xDC6803bE2AEdEf0383E25AB1f81959B048E614A4");

    service = await deployUtils.deploy("BadgeCollectorService");
    upgradeableService = await deployUtils.deploy("BadgeCollectorServiceUpgradeable");
    upgradeableServiceProxy = await deployUtils.deploy("BadgeCollectorServiceUpgradeableProxy", await upgradeableService.getAddress());

    nft = await deployUtils.deploy("SomeNiceNFT", deployer.address);

  });

  it("should deploy everything as expected", async function () {

  });

  it("should associate the service to the NFT and verify that the service has been deployed", async function () {

    // mint an nft
    await nft.safeMint(bob.address, 1);
// convert the chainId to a bytes32
    const chainIdBytes32 = "0x" + chainId.toString(16).padStart(64, "0");

    const tx = await registry.create(await service.getAddress(), salt0, chainIdBytes32, await nft.getAddress(), 1);
    await tx.wait();
    const deployedAddress = await registry.compute(await service.getAddress(), salt0, chainIdBytes32, await nft.getAddress(), 1);

    // verify that the service has been deployed, i.e., the code is not zero
    const code = await ethers.provider.getCode(deployedAddress);
    expect(code).not.equal("0x");

    const serviceArtifacts = await artifacts.readArtifact("BadgeCollectorService");
    const abi = serviceArtifacts.abi;

    const deployedService = new ethers.Contract(deployedAddress, serviceArtifacts.abi, ethers.provider);

    expect(await deployedService.owner()).equal(bob.address);

  });

});
