const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("AccountInheritanceService", function () {
  let inheritanceService;
  let mockNFT;
  let mockERC4337Account;
  let owner;
  let heir;
  let other;
  let mockNFTAddress;
  let mockERC4337AccountAddress;
  let inheritanceServiceAddress;
  let factory;
  let chainId;

  async function deployContractsFixture() {
    [owner, heir, other] = await ethers.getSigners();

    // Deploy mock contracts
    const MockNFT = await ethers.getContractFactory("MockNFT");
    mockNFT = await MockNFT.deploy();
    await mockNFT.waitForDeployment();

    const MockERC4337Account = await ethers.getContractFactory("MockERC4337Account");
    mockERC4337Account = await MockERC4337Account.deploy();
    await mockERC4337Account.waitForDeployment();

    // Deploy factory
    const Factory = await ethers.getContractFactory("ERC7656Factory");
    factory = await Factory.deploy();
    await factory.waitForDeployment();

    // Deploy implementation
    const AccountInheritanceService = await ethers.getContractFactory("AccountInheritanceService");
    const inheritanceServiceImpl = await AccountInheritanceService.deploy();
    await inheritanceServiceImpl.waitForDeployment();

    // Get addresses
    mockNFTAddress = await mockNFT.getAddress();
    mockERC4337AccountAddress = await mockERC4337Account.getAddress();
    const implAddress = await inheritanceServiceImpl.getAddress();

    // Get chainId
    chainId = await ethers.provider.getNetwork().then(n => n.chainId);
    const chainIdBytes32 = ethers.zeroPadValue(ethers.toBeHex(chainId), 32);
    const salt = ethers.randomBytes(32);
    const mode = "0x000000000000000000000001"; // NO_LINKED_ID mode for account inheritance

    // Get deployed service address first
    inheritanceServiceAddress = await factory.compute(
      implAddress,
      salt,
      chainId,
      mode,
      mockERC4337AccountAddress,
      0
    );

    // Setup mock ERC4337 account with the computed service address
    await mockERC4337Account.initialize(inheritanceServiceAddress);
    // The owner is already set in the constructor to msg.sender (which is owner in this case)

    // Deploy service through factory
    await factory.create(
      implAddress,
      salt,
      chainId,
      mode,
      mockERC4337AccountAddress,
      0 // No linked ID for account inheritance
    );

    inheritanceService = await ethers.getContractAt("AccountInheritanceService", inheritanceServiceAddress);

    return {
      inheritanceService,
      mockNFT,
      mockERC4337Account,
      owner,
      heir,
      other,
      mockNFTAddress,
      mockERC4337AccountAddress,
      inheritanceServiceAddress,
      factory,
      chainId
    };
  }

  beforeEach(async function () {
    const fixture = await loadFixture(deployContractsFixture);
    Object.assign(this, fixture);
  });

  describe("Inheritance Setup", function () {
    it("should allow setting up inheritance for an ERC-4337 account", async function () {
      const tokenId = 1;
      const inheritanceDelay = 86400; // 1 day

      const setBeneficiaryData = inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await expect(
        this.mockERC4337Account.execute(
          this.inheritanceServiceAddress,
          0,
          setBeneficiaryData
        )
      )
        .to.emit(this.inheritanceService, "BeneficiarySet")
        .withArgs(
          this.mockERC4337AccountAddress,
          this.heir.address
        );

      const inheritance = await this.inheritanceService.getInheritanceData();

      expect(inheritance.beneficiary).to.equal(this.heir.address);
      expect(inheritance.gracePeriod).to.equal(inheritanceDelay);
      expect(inheritance.lastProofOfLife).to.be.gt(0);
    });

    it("should not allow setting up inheritance for non-ERC-4337 accounts", async function () {
      const tokenId = 1;
      const inheritanceDelay = 86400;

      const setBeneficiaryData = inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await expect(
        this.mockERC4337Account.connect(this.other).execute(
          this.inheritanceServiceAddress,
          0,
          setBeneficiaryData
        )
      ).to.be.revertedWith("Not authorized");
    });

    it("should not allow setting up inheritance for non-owner", async function () {
      const tokenId = 1;
      const inheritanceDelay = 86400;

      const setBeneficiaryData = inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await expect(
        this.mockERC4337Account.connect(this.other).execute(
          this.inheritanceServiceAddress,
          0,
          setBeneficiaryData
        )
      ).to.be.revertedWith("Not authorized");
    });
  });

  describe("Inheritance Claim", function () {
    beforeEach(async function () {
      const tokenId = 1;
      const inheritanceDelay = 86400;

      const setBeneficiaryData = inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await this.mockERC4337Account.execute(
        this.inheritanceServiceAddress,
        0,
        setBeneficiaryData
      );

      // Mint NFT to the ERC-4337 account
      await this.mockNFT.mint(this.mockERC4337AccountAddress, tokenId);
    });

    it("should allow heir to claim inheritance after delay", async function () {
      const tokenId = 1;

      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [86400]);
      await ethers.provider.send("evm_mine");

      // First, we need to prepare the transferOwnership call that the service will make
      const transferOwnershipData = this.mockERC4337Account.interface.encodeFunctionData("transferOwnership", [
        this.heir.address
      ]);

      // Then we execute the claim through the service
      await expect(
        this.inheritanceService.connect(this.heir).claimAccount()
      )
        .to.emit(this.inheritanceService, "AccountClaimed")
        .withArgs(
          this.mockERC4337AccountAddress,
          this.heir.address
        );

      expect(await this.mockERC4337Account.owner()).to.equal(this.heir.address);
    });

    it("should not allow claiming before delay period", async function () {
      const tokenId = 1;

      await expect(
        this.inheritanceService.connect(this.heir).claimAccount()
      ).to.be.revertedWithCustomError(this.inheritanceService, "GracePeriodNotExpired");
    });

    it("should not allow non-heir to claim inheritance", async function () {
      const tokenId = 1;

      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [86400]);
      await ethers.provider.send("evm_mine");

      await expect(
        this.inheritanceService.connect(this.other).claimAccount()
      ).to.be.revertedWithCustomError(this.inheritanceService, "NotOwner");
    });
  });

  describe("Inheritance Cancellation", function () {
    beforeEach(async function () {
      const tokenId = 1;
      const inheritanceDelay = 86400;

      const setBeneficiaryData = inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await this.mockERC4337Account.execute(
        this.inheritanceServiceAddress,
        0,
        setBeneficiaryData
      );
    });

    it("should allow owner to cancel inheritance", async function () {
      const tokenId = 1;

      const setBeneficiaryData = inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        ethers.ZeroAddress,
        0
      ]);

      await expect(
        this.mockERC4337Account.execute(
          this.inheritanceServiceAddress,
          0,
          setBeneficiaryData
        )
      )
        .to.emit(this.inheritanceService, "BeneficiarySet")
        .withArgs(
          this.mockERC4337AccountAddress,
          ethers.ZeroAddress
        );

      const inheritance = await this.inheritanceService.getInheritanceData();

      expect(inheritance.beneficiary).to.equal(ethers.ZeroAddress);
      expect(inheritance.gracePeriod).to.equal(0);
      expect(inheritance.lastProofOfLife).to.be.gt(0);
    });

    it("should not allow non-owner to cancel inheritance", async function () {
      const tokenId = 1;

      const setBeneficiaryData = inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        ethers.ZeroAddress,
        0
      ]);

      await expect(
        this.mockERC4337Account.connect(this.other).execute(
          this.inheritanceServiceAddress,
          0,
          setBeneficiaryData
        )
      ).to.be.revertedWith("Not authorized");
    });
  });
});
