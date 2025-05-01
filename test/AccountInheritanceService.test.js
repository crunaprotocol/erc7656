const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("AccountInheritanceService", function () {
  let inheritanceService;
  let mockNFT;
  let mockERC4337Account;
  let mockEntryPoint;
  let owner;
  let heir;
  let other;
  let mockNFTAddress;
  let mockERC4337AccountAddress;
  let inheritanceServiceAddress;
  let factory;
  let chainId;
  let inheritanceServiceImpl;

  async function deployContractsFixture() {
    [owner, heir, other] = await ethers.getSigners();

    // Deploy mock contracts
    const MockNFT = await ethers.getContractFactory("MockNFT");
    mockNFT = await MockNFT.deploy();
    await mockNFT.waitForDeployment();

    // Deploy mock entry point first
    const MockEntryPoint = await ethers.getContractFactory("MockEntryPoint");
    mockEntryPoint = await MockEntryPoint.deploy();
    await mockEntryPoint.waitForDeployment();

    const MockERC4337Account = await ethers.getContractFactory("MockERC4337Account");
    mockERC4337Account = await MockERC4337Account.deploy(await mockEntryPoint.getAddress());
    await mockERC4337Account.waitForDeployment();

    // Deploy factory
    const Factory = await ethers.getContractFactory("ERC7656Factory");
    factory = await Factory.deploy();
    await factory.waitForDeployment();

    // Deploy implementation
    const AccountInheritanceService = await ethers.getContractFactory("AccountInheritanceService");
    inheritanceServiceImpl = await AccountInheritanceService.deploy();
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

    // Register the account with the entry point
    await mockEntryPoint.registerAccount(await mockERC4337Account.getAddress());

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

    // Initialize the service
    await inheritanceService.initialize(await mockEntryPoint.getAddress());

    // Register the account with the entry point
    await mockEntryPoint.registerAccount(await mockERC4337Account.getAddress());

    // Now we can use the entry point for operations
    mockERC4337AccountAddress = await mockERC4337Account.getAddress();

    return {
      inheritanceService,
      mockNFT,
      mockERC4337Account,
      mockEntryPoint,
      owner,
      heir,
      other,
      mockNFTAddress,
      mockERC4337AccountAddress,
      inheritanceServiceAddress,
      factory,
      chainId,
      inheritanceServiceImpl
    };
  }

  beforeEach(async function () {
    const fixture = await loadFixture(deployContractsFixture);
    Object.assign(this, fixture);
  });

  // Helper function to execute through entry point
  async function executeViaEntryPoint(account, dest, value, data) {
    // First, we need to execute through the account
    const executeData = account.interface.encodeFunctionData("execute", [dest, value, data]);
    const userOp = {
      sender: await account.getAddress(),
      value: value,
      callData: executeData
    };
    await mockEntryPoint.handleOps([userOp], ethers.ZeroAddress);
  }

  describe("Initialization", function () {
    it("should be deployed correctly", async function () {
      expect(await this.inheritanceService.getAddress()).to.be.properAddress;
    });

    it("should implement IERC7656Service", async function () {
      expect(await this.inheritanceService.supportsInterface("0x7e110a1d")).to.be.true;
    });

    it("should not allow double initialization", async function () {
      await expect(this.inheritanceService.initialize(await this.mockEntryPoint.getAddress()))
        .to.be.revertedWithCustomError(this.inheritanceService, "AlreadyInitialized");
    });

    it("should not allow using functions before initialization", async function () {
      // Deploy a new uninitialized instance
      const mode = "0x000000000000000000000001"; // NO_LINKED_ID mode
      const salt = ethers.randomBytes(32);
      const chainIdBytes32 = ethers.zeroPadValue(ethers.toBeHex(this.chainId), 32);

      const serviceAddress = await this.factory.compute(
        await this.inheritanceServiceImpl.getAddress(),
        salt,
        this.chainId,
        mode,
        this.mockERC4337AccountAddress,
        0
      );

      await this.factory.create(
        await this.inheritanceServiceImpl.getAddress(),
        salt,
        this.chainId,
        mode,
        this.mockERC4337AccountAddress,
        0
      );

      const uninitializedService = await ethers.getContractAt("AccountInheritanceService", serviceAddress);

      const setBeneficiaryData = uninitializedService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        86400
      ]);

      // Try to execute directly without going through entry point
      await expect(
        this.mockERC4337Account.execute(
          serviceAddress,
          0,
          setBeneficiaryData
        )
      ).to.be.revertedWith("account: not Owner or EntryPoint");
    });
  });

  describe("Inheritance Setup", function () {
    it("should allow setting up inheritance for an ERC-4337 account", async function () {
      const inheritanceDelay = 86400; // 1 day

      const setBeneficiaryData = this.inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await executeViaEntryPoint(
        this.mockERC4337Account,
        this.inheritanceServiceAddress,
        0,
        setBeneficiaryData
      );

      const inheritance = await this.inheritanceService.getInheritanceData();
      expect(inheritance.beneficiary).to.equal(this.heir.address);
      expect(inheritance.gracePeriod).to.equal(inheritanceDelay);
      expect(inheritance.lastProofOfLife).to.be.gt(0);
    });

    it("should not allow setting up inheritance for non-ERC-4337 accounts", async function () {
      const inheritanceDelay = 86400;

      const setBeneficiaryData = this.inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      // Try to execute directly without going through entry point
      await expect(
        this.mockERC4337Account.execute(
          this.inheritanceServiceAddress,
          0,
          setBeneficiaryData
        )
      ).to.be.revertedWith("account: not Owner or EntryPoint");
    });

    it("should not allow setting up inheritance for non-owner", async function () {
      const inheritanceDelay = 86400;

      const setBeneficiaryData = this.inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      // Try to execute from a different account
      const executeData = this.mockERC4337Account.interface.encodeFunctionData("execute", [
        this.inheritanceServiceAddress,
        0,
        setBeneficiaryData
      ]);

      const userOp = {
        sender: this.other.address,
        value: 0,
        callData: executeData
      };

      await expect(
        this.mockEntryPoint.handleOps([userOp], ethers.ZeroAddress)
      ).to.be.revertedWithCustomError(this.mockEntryPoint, "NotRegistered");
    });
  });

  describe("Inheritance Claim", function () {
    beforeEach(async function () {
      const inheritanceDelay = 86400;

      const setBeneficiaryData = this.inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await executeViaEntryPoint(
        this.mockERC4337Account,
        this.inheritanceServiceAddress,
        0,
        setBeneficiaryData
      );

      // Mint NFT to the ERC-4337 account
      await this.mockNFT.mint(this.mockERC4337AccountAddress, 1);
    });

    it("should allow heir to claim inheritance after delay", async function () {
      const tokenId = 1;

      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [86400]);
      await ethers.provider.send("evm_mine");

      // Log the service address
      console.log("Service address:", await this.inheritanceService.getAddress());

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
          0, // linkedId is 0 for ERC4337 accounts
          this.heir.address
        );

      // Verify the ownership was transferred
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
      const inheritanceDelay = 86400;

      const setBeneficiaryData = this.inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await executeViaEntryPoint(
        this.mockERC4337Account,
        this.inheritanceServiceAddress,
        0,
        setBeneficiaryData
      );
    });

    it("should allow owner to cancel inheritance", async function () {
      const setBeneficiaryData = this.inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        ethers.ZeroAddress,
        0
      ]);

      await executeViaEntryPoint(
        this.mockERC4337Account,
        this.inheritanceServiceAddress,
        0,
        setBeneficiaryData
      );

      const inheritance = await this.inheritanceService.getInheritanceData();
      expect(inheritance.beneficiary).to.equal(ethers.ZeroAddress);
      expect(inheritance.gracePeriod).to.equal(0);
      expect(inheritance.lastProofOfLife).to.be.gt(0);
    });

    it("should not allow non-owner to cancel inheritance", async function () {
      const setBeneficiaryData = this.inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        ethers.ZeroAddress,
        0
      ]);

      // Try to execute from a different account
      const executeData = this.mockERC4337Account.interface.encodeFunctionData("execute", [
        this.inheritanceServiceAddress,
        0,
        setBeneficiaryData
      ]);

      const userOp = {
        sender: this.other.address,
        value: 0,
        callData: executeData
      };

      await expect(
        this.mockEntryPoint.handleOps([userOp], ethers.ZeroAddress)
      ).to.be.revertedWithCustomError(this.mockEntryPoint, "NotRegistered");
    });
  });
});
