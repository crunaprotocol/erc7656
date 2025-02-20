const {expect} = require("chai");
const {ethers} = require("hardhat");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();
const bytecodes = require("../contracts/bytecode.json");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

const {
  cl,
  amount,
  normalize,
  assertThrowsMessage,
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
  let chainId, chainIdBytes32;
  let badgeCollectorImpl, nft;
  let magicBadge, collBadge, superTransferableBadge;
  let badgeCollector;
  const salt0 = "0x" + "0".repeat(64);

  before(async function () {
    [deployer, bob, alice, fred, mark] = await ethers.getSigners();
    await deployUtils.deployNickSFactory(deployer);

    chainId = await getChainId();
    chainIdBytes32 = "0x" + chainId.toString(16).padStart(64, "0");
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

    expect(await registry.supportsInterface("0xc6bdc908")).equal(true);
  });

  async function initAndDeploy() {
    badgeCollectorImpl = await deployUtils.deploy("BadgeCollectorService");

    nft = await deployUtils.deploy("SomeNiceNFT", deployer.address);

    magicBadge = await deployUtils.deploy("MagicBadge", deployer.address);
    collBadge = await deployUtils.deploy("CoolBadge", deployer.address);
    superTransferableBadge = await deployUtils.deploy("SuperTransferableBadge", deployer.address);
  }

  beforeEach(async function () {
    await initAndDeploy();
  });

  it("should deploy and initiate everything", async function () {
  });

  it("should associate the service to the NFT and verify that the service has been deployed", async function () {

    let id = 1;
    // mint an nft
    await nft.safeMint(bob.address, id);

    await expect(registry.create(await badgeCollectorImpl.getAddress(), salt0, chainIdBytes32, await nft.getAddress(), id)).emit(registry, "Created").withArgs(anyValue, await badgeCollectorImpl.getAddress(), salt0, chainIdBytes32, await nft.getAddress(), id);

    const serviceAddress = await registry.compute(await badgeCollectorImpl.getAddress(), salt0, chainIdBytes32, await nft.getAddress(), id);

    // verify that the service has been deployed, i.e., the code is not zero
    const code = await ethers.provider.getCode(serviceAddress);
    expect(code).not.equal("0x");

    badgeCollector = await deployUtils.getContract("BadgeCollectorService", serviceAddress);

    expect(await badgeCollector.supportsInterface("0xfc0c546a")).equal(true);

    expect(await badgeCollector.owner()).equal(bob.address);
    const token = await badgeCollector.token();

    expect(token[0]).equal(chainId);
    expect(token[1]).equal(await nft.getAddress());
    expect(token[2]).equal(id);

    expect(await badgeCollector.salt()).equal(salt0);
    expect(await badgeCollector.tokenAddress()).equal(await nft.getAddress());
    expect(await badgeCollector.tokenId()).equal(id);
    expect(await badgeCollector.implementation()).equal(await badgeCollectorImpl.getAddress());

    const context = await badgeCollector.context();
    expect(context[0]).equal(salt0);
    expect(context[1]).equal(chainId);
    expect(context[2]).equal(await nft.getAddress());
    expect(context[3]).equal(id);
  });

  it("should use and verify the service", async function () {

    let id = 1;
    // mint an nft
    await nft.safeMint(bob.address, id);

    await registry.create(await badgeCollectorImpl.getAddress(), salt0, chainIdBytes32, await nft.getAddress(), id);
    const serviceAddress = await registry.compute(await badgeCollectorImpl.getAddress(), salt0, chainIdBytes32, await nft.getAddress(), id);

    badgeCollector = await deployUtils.getContract("BadgeCollectorService", serviceAddress);

    await expect(collBadge.safeMint(serviceAddress, id)).emit(collBadge, "Transfer").withArgs(addr0, serviceAddress, id);

    await expect(magicBadge.safeMint(serviceAddress, id)).emit(magicBadge, "Transfer").withArgs(addr0, serviceAddress, id);

    await expect(superTransferableBadge.safeMint(serviceAddress, id))
        .emit(superTransferableBadge, "Transfer")
        .withArgs(addr0, serviceAddress, id);

    await assertThrowsMessage(badgeCollector.connect(bob).transferBadgeToOwner(await collBadge.getAddress(), id), "NotTransferable");

    await expect(badgeCollector.connect(bob).transferBadgeToOwner(await superTransferableBadge.getAddress(), id))
        .emit(superTransferableBadge, "Transfer")
        .withArgs(serviceAddress, bob.address, id);

    expect(await superTransferableBadge.firstOwnerOf(id)).equal(serviceAddress);
  });

});
