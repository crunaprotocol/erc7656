const { expect } = require("chai");
const { ethers } = require("hardhat");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();
const bytecodes = require("../contracts/bytecode.json");

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

describe("SimpleInheritanceService", function () {
  let factory;
  let deployer, owner, beneficiary;
  let chainId, chainIdBytes32;
  let nft;
  let inheritanceServiceImpl;
  let inheritanceService;
  const salt = "0x" + "aabbccdd".repeat(8);
  const tokenId = 1;
  const gracePeriod = 30 * 24 * 60 * 60; // 30 days in seconds

  before(async function () {
    [deployer, owner, beneficiary] = await ethers.getSigners();
    await deployUtils.deployNickSFactory(deployer);

    chainId = await getChainId();
    chainIdBytes32 = "0x" + chainId.toString(16).padStart(64, "0");

    factory = await deployUtils.deployBytecodeViaNickSFactory(
      deployer,
      "ERC7656Factory",
      bytecodes.bytecode,
      bytecodes.salt,
    );

    // Deploy inheritance service implementation
    inheritanceServiceImpl = await deployUtils.deploy("SimpleInheritanceService");
  });

  beforeEach(async function () {
    // Deploy a fresh NFT contract for each test
    nft = await deployUtils.deploy("StandardNFT", deployer.address);
    await nft.safeMint(owner.address, tokenId);

    // Deploy a new instance of the inheritance service for each test
    const mode = "0x000000000000000000000000"; // LINKED_ID mode
    const linkedId = "0x" + tokenId.toString(16).padStart(64, "0");

    const serviceAddress = await factory.compute(
      await inheritanceServiceImpl.getAddress(),
      salt,
      chainIdBytes32,
      mode,
      await nft.getAddress(),
      linkedId
    );

    await factory.create(
      await inheritanceServiceImpl.getAddress(),
      salt,
      chainIdBytes32,
      mode,
      await nft.getAddress(),
      linkedId
    );

    inheritanceService = await ethers.getContractAt("SimpleInheritanceService", serviceAddress);
    
    // Initialize the service
    await inheritanceService.initialize();
  });

  describe("Initialization", function () {
    it("should be deployed correctly", async function () {
      expect(await inheritanceService.getAddress()).to.be.properAddress;
    });

    it("should implement IERC7656Service", async function () {
      expect(await inheritanceService.supportsInterface("0x7e110a1d")).to.be.true;
    });

    it("should not allow double initialization", async function () {
      await expect(inheritanceService.initialize())
        .to.be.revertedWithCustomError(inheritanceService, "AlreadyInitialized");
    });

    it("should not allow using functions before initialization", async function () {
      // Deploy a new uninitialized instance
      const mode = "0x000000000000000000000000"; // LINKED_ID mode
      const newTokenId = 2;
      const linkedId = "0x" + newTokenId.toString(16).padStart(64, "0");
      const newSalt = ethers.randomBytes(32);

      const serviceAddress = await factory.compute(
        await inheritanceServiceImpl.getAddress(),
        newSalt,
        chainIdBytes32,
        mode,
        await nft.getAddress(),
        linkedId
      );

      await factory.create(
        await inheritanceServiceImpl.getAddress(),
        newSalt,
        chainIdBytes32,
        mode,
        await nft.getAddress(),
        linkedId
      );

      const uninitializedService = await ethers.getContractAt("SimpleInheritanceService", serviceAddress);

      await expect(uninitializedService.setBeneficiary(beneficiary.address, gracePeriod))
        .to.be.revertedWithCustomError(uninitializedService, "NotInitialized");
    });
  });

  describe("Beneficiary Management", function () {
    it("should allow owner to set beneficiary", async function () {
      await expect(inheritanceService.connect(owner).setBeneficiary(beneficiary.address, gracePeriod))
        .to.emit(inheritanceService, "BeneficiarySet")
        .withArgs(await nft.getAddress(), tokenId, beneficiary.address);

      const inheritanceData = await inheritanceService.getInheritanceData();
      expect(inheritanceData.beneficiary).to.equal(beneficiary.address);
      expect(inheritanceData.gracePeriod).to.equal(gracePeriod);
    });

    it("should not allow non-owner to set beneficiary", async function () {
      await expect(
        inheritanceService.connect(beneficiary).setBeneficiary(beneficiary.address, gracePeriod)
      ).to.be.revertedWithCustomError(inheritanceService, "NotOwner");
    });
  });

  describe("Proof of Life", function () {
    beforeEach(async function () {
      await inheritanceService.connect(owner).setBeneficiary(beneficiary.address, gracePeriod);
    });

    it("should allow owner to provide proof of life", async function () {
      await expect(inheritanceService.connect(owner).provideProofOfLife())
        .to.emit(inheritanceService, "ProofOfLifeProvided")
        .withArgs(await nft.getAddress(), tokenId);

      const inheritanceData = await inheritanceService.getInheritanceData();
      expect(inheritanceData.lastProofOfLife).to.be.gt(0);
    });

    it("should not allow non-owner to provide proof of life", async function () {
      await expect(
        inheritanceService.connect(beneficiary).provideProofOfLife()
      ).to.be.revertedWithCustomError(inheritanceService, "NotOwner");
    });
  });

  describe("NFT Claiming", function () {
    beforeEach(async function () {
      await inheritanceService.connect(owner).setBeneficiary(beneficiary.address, gracePeriod);
    });

    it("should not allow claiming before grace period expires", async function () {
      await expect(
        inheritanceService.connect(beneficiary).claimNFT()
      ).to.be.revertedWithCustomError(inheritanceService, "GracePeriodNotExpired");
    });

    it("should not allow non-beneficiary to claim", async function () {
      // Fast forward time past grace period
      await ethers.provider.send("evm_increaseTime", [gracePeriod + 1]);
      await ethers.provider.send("evm_mine");

      await expect(
        inheritanceService.connect(owner).claimNFT()
      ).to.be.revertedWithCustomError(inheritanceService, "NotOwner");
    });

    it("should allow beneficiary to claim after grace period expires", async function () {
      // Fast forward time past grace period
      await ethers.provider.send("evm_increaseTime", [gracePeriod + 1]);
      await ethers.provider.send("evm_mine");

      // Transfer the NFT to the inheritance service first
      await nft.connect(owner).transferFrom(owner.address, inheritanceService.getAddress(), tokenId);

      await expect(inheritanceService.connect(beneficiary).claimNFT())
        .to.emit(inheritanceService, "NFTClaimed")
        .withArgs(await nft.getAddress(), tokenId, beneficiary.address);

      expect(await nft.ownerOf(tokenId)).to.equal(beneficiary.address);
    });

    it("should not allow claiming if proof of life is provided within grace period", async function () {
      // Fast forward time to just before grace period expires
      await ethers.provider.send("evm_increaseTime", [gracePeriod - 1]);
      await ethers.provider.send("evm_mine");

      // Provide proof of life
      await inheritanceService.connect(owner).provideProofOfLife();

      // Fast forward past original grace period
      await ethers.provider.send("evm_increaseTime", [2]);
      await ethers.provider.send("evm_mine");

      await expect(
        inheritanceService.connect(beneficiary).claimNFT()
      ).to.be.revertedWithCustomError(inheritanceService, "GracePeriodNotExpired");
    });
  });
}); 