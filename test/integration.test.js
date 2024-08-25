const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");

const {
  deployCanonical,
  normalize,
  getChainId,
  bytes4,
  cl,
  pluginKey,
  increaseBlockTimestampBy,
  getTimestamp
} = require("./helpers/index");

describe("MyExpandableToken", function () {
  let myExpandableToken, erc7656Registry, mockPluginImplementation;
  let deployer, alice, bob;
  const CANONICAL_ERC7656_REGISTRY = "0x7656f0fB4Ca6973cf99D910B36705a2dEDA97eA1";

  before(async function () {
    [deployer, alice, bob] = await ethers.getSigners();
    cl("Deployer address:", deployer.address);
    cl("Alice address:", alice.address);
    cl("Bob address:", bob.address);

    // Deploy MyExpandableToken
    const MyExpandableToken = await ethers.getContractFactory("MyExpandableToken");
    myExpandableToken = await MyExpandableToken.deploy(deployer.address);
    await myExpandableToken.deployed();

    // Verify the owner
    const owner = await myExpandableToken.owner();
    cl("Contract owner after deployment:", owner);

    // Get the ERC7656Registry instance
    erc7656Registry = await ethers.getContractAt("IERC7656Registry", CANONICAL_ERC7656_REGISTRY);

    // Deploy a mock plugin implementation
    const MockPlugin = await ethers.getContractFactory("MockPlugin");
    mockPluginImplementation = await MockPlugin.deploy();
    await mockPluginImplementation.deployed();
  });

  beforeEach(async function () {
    // Try minting
    try {
      const tx = await myExpandableToken.connect(deployer).safeMint(alice.address, 1);
      await tx.wait(); // Wait for the transaction to be mined
      cl("Minting successful");
    } catch (error) {
      cl("Minting error:", error.message);
      // Log the full error object if needed
      cl(JSON.stringify(error, null, 2));
    }

    const balanceOf = await myExpandableToken.balanceOf(alice.address);
    expect(balanceOf).to.equal(1);
  });

  it("should have correct name and symbol", async function () {
    expect(await myExpandableToken.name()).to.equal("MyExpandableToken");
    expect(await myExpandableToken.symbol()).to.equal("MET");
  });

  it("should allow owner to mint tokens", async function () {
    await expect(myExpandableToken.connect(deployer).safeMint(bob.address, 2))
      .to.emit(myExpandableToken, "Transfer")
      .withArgs(ethers.constants.AddressZero, bob.address, 2);
  });

  it("should not allow non-owner to mint tokens", async function () {
    await expect(myExpandableToken.connect(alice).safeMint(alice.address, 3))
      .to.be.revertedWith("OwnableUnauthorizedAccount");
  });

  it.only("should allow token owner to deploy a plugin", async function () {
    const salt = ethers.utils.formatBytes32String("test-salt");

    await expect(myExpandableToken.connect(alice).deployContractsOwnedByTheTokenId(
      mockPluginImplementation.address,
      salt,
      1
    )).to.emit(erc7656Registry, "Created");
  });

  it("should not allow non-token owner to deploy a plugin", async function () {
    const salt = ethers.utils.formatBytes32String("test-salt");

    await expect(myExpandableToken.connect(bob).deployContractsOwnedByTheTokenId(
      mockPluginImplementation.address,
      salt,
      1
    )).to.be.revertedWith("NotTheTokenOwner");
  });

  it("should deploy plugin to the correct address", async function () {
    const salt = ethers.utils.formatBytes32String("test-salt");

    const tx = await myExpandableToken.connect(alice).deployContractsOwnedByTheTokenId(
      mockPluginImplementation.address,
      salt,
      1
    );
    const receipt = await tx.wait();

    const createdEvent = receipt.events.find(e => e.event === "Created");
    const deployedAddress = createdEvent.args.contractAddress;

    const computedAddress = await erc7656Registry.compute(
      mockPluginImplementation.address,
      salt,
      await myExpandableToken.provider.getNetwork().then(n => n.chainId),
      myExpandableToken.address,
      1
    );

    expect(deployedAddress).to.equal(computedAddress);
  });
});