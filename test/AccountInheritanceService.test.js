const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { ecsign, toRpcSig } = require("ethereumjs-util");

// Create a deterministic wallet for signing
function createAccountOwner() {
  const counter = 1; // Use a fixed counter for deterministic results
  const privateKey = ethers.keccak256(ethers.toUtf8Bytes(counter.toString()));
  return new ethers.Wallet(privateKey, ethers.provider);
}

// Pack user operation
function packUserOp(userOp) {
  const accountGasLimits = ethers.solidityPacked(
    ["uint128", "uint128"],
    [userOp.verificationGasLimit, userOp.callGasLimit]
  );
  const gasFees = ethers.solidityPacked(
    ["uint128", "uint128"],
    [userOp.maxPriorityFeePerGas, userOp.maxFeePerGas]
  );
  let paymasterAndData = "0x";
  if (userOp.paymaster?.length >= 20 && userOp.paymaster !== ethers.ZeroAddress) {
    paymasterAndData = ethers.solidityPacked(
      ["address", "uint256", "uint256", "bytes"],
      [userOp.paymaster, userOp.paymasterVerificationGasLimit, userOp.paymasterPostOpGasLimit, userOp.paymasterData]
    );
  }
  return {
    sender: userOp.sender,
    nonce: userOp.nonce,
    callData: userOp.callData,
    accountGasLimits,
    initCode: userOp.initCode,
    preVerificationGas: userOp.preVerificationGas,
    gasFees,
    paymasterAndData,
    signature: userOp.signature
  };
}

// Encode user operation for signing
function encodeUserOp(userOp, forSignature = true) {
  const PACKED_USEROP_TYPEHASH = ethers.keccak256(
    ethers.toUtf8Bytes("PackedUserOperation(address sender,uint256 nonce,bytes initCode,bytes callData,bytes32 accountGasLimits,uint256 preVerificationGas,bytes32 gasFees,bytes paymasterAndData)")
  );

  const packedUserOp = packUserOp(userOp);
  if (forSignature) {
    return ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "address", "uint256", "bytes32", "bytes32", "bytes32", "uint256", "bytes32", "bytes32"],
      [
        PACKED_USEROP_TYPEHASH,
        packedUserOp.sender,
        packedUserOp.nonce,
        ethers.keccak256(packedUserOp.initCode || "0x"),
        ethers.keccak256(packedUserOp.callData || "0x"),
        packedUserOp.accountGasLimits,
        packedUserOp.preVerificationGas,
        packedUserOp.gasFees,
        ethers.keccak256(packedUserOp.paymasterAndData || "0x")
      ]
    );
  } else {
    // for the purpose of calculating gas cost encode also signature (and no keccak of bytes)
    return ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "address", "uint256", "bytes", "bytes", "bytes32", "uint256", "bytes32", "bytes", "bytes"],
      [
        PACKED_USEROP_TYPEHASH,
        packedUserOp.sender,
        packedUserOp.nonce,
        packedUserOp.initCode || "0x",
        packedUserOp.callData || "0x",
        packedUserOp.accountGasLimits,
        packedUserOp.preVerificationGas,
        packedUserOp.gasFees,
        packedUserOp.paymasterAndData || "0x",
        packedUserOp.signature || "0x"
      ]
    );
  }
}

// Get domain separator
function getDomainSeparator(entryPoint, chainId) {
  const DOMAIN_NAME = "ERC4337";
  const DOMAIN_VERSION = "1";
  const domainSeparator = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "bytes32", "bytes32", "uint256", "address"],
      [
        ethers.keccak256(ethers.toUtf8Bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")),
        ethers.keccak256(ethers.toUtf8Bytes(DOMAIN_NAME)),
        ethers.keccak256(ethers.toUtf8Bytes(DOMAIN_VERSION)),
        chainId,
        entryPoint
      ]
    )
  );
  return domainSeparator;
}

// Get user operation hash
function getUserOpHash(userOp, entryPoint, chainId) {
  const packed = encodeUserOp(userOp);
  return ethers.keccak256(
    ethers.concat([
      "0x1901",
      getDomainSeparator(entryPoint, chainId),
      ethers.keccak256(packed)
    ])
  );
}

// Default values for user operations
const DefaultsForUserOp = {
  sender: ethers.ZeroAddress,
  nonce: 0,
  initCode: "0x",
  callData: "0x",
  callGasLimit: 0,
  verificationGasLimit: 150000, // default verification gas. will add create2 cost (3200+200*length) if initCode exists
  preVerificationGas: 21000, // should also cover calldata cost.
  maxFeePerGas: 0,
  maxPriorityFeePerGas: 1e9,
  paymaster: ethers.ZeroAddress,
  paymasterData: "0x",
  paymasterVerificationGasLimit: 3e5,
  paymasterPostOpGasLimit: 0,
  signature: "0x"
};

// Fill user operation defaults
function fillUserOpDefaults(op, defaults = DefaultsForUserOp) {
  const partial = { ...op };
  // we want "item:undefined" to be used from defaults, and not override defaults, so we must explicitly
  // remove those so "merge" will succeed.
  for (const key in partial) {
    if (partial[key] == null) {
      delete partial[key];
    }
  }
  const filled = { ...defaults, ...partial };
  return filled;
}

describe("AccountInheritanceService", function () {
  let inheritanceService;
  let mockNFT;
  let mockERC4337Account;
  let entryPoint;
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

    // Create a deterministic wallet for the account owner
    const accountOwner = createAccountOwner();

    // Deploy mock contracts
    const MockNFT = await ethers.getContractFactory("MockNFT");
    mockNFT = await MockNFT.deploy();
    await mockNFT.waitForDeployment();

    // Deploy the official EntryPoint
    const EntryPoint = await ethers.getContractFactory("EntryPoint");
    entryPoint = await EntryPoint.deploy();
    await entryPoint.waitForDeployment();

    // Deploy the factory
    const MockERC4337AccountFactory = await ethers.getContractFactory("MockERC4337AccountFactory");
    const accountFactory = await MockERC4337AccountFactory.deploy(await entryPoint.getAddress());
    await accountFactory.waitForDeployment();

    // Get the sender creator from the entry point
    const senderCreator = await entryPoint.senderCreator();
    
    // Set the sender creator's balance using hardhat_setBalance
    await ethers.provider.send("hardhat_setBalance", [senderCreator, ethers.toBeHex(ethers.parseEther("100.0"))]);

    // Impersonate the sender creator
    await ethers.provider.send("hardhat_impersonateAccount", [senderCreator]);
    const senderCreatorSigner = await ethers.getSigner(senderCreator);

    // Deploy the account through the factory using the sender creator
    const accountSalt = 0; // Use 0 as salt for simplicity in tests
    mockERC4337AccountAddress = await accountFactory.getAddress(await accountOwner.getAddress(), accountSalt);
    console.log("Expected account address:", mockERC4337AccountAddress);
    
    const tx = await accountFactory.connect(senderCreatorSigner).createAccount(await accountOwner.getAddress(), accountSalt);
    await tx.wait();

    // Stop impersonating the sender creator
    await ethers.provider.send("hardhat_stopImpersonatingAccount", [senderCreator]);
    
    // Get the deployed account instance using the actual contract ABI
    const MockERC4337Account = await ethers.getContractFactory("MockERC4337Account");
    mockERC4337Account = await MockERC4337Account.attach(mockERC4337AccountAddress);
    console.log("Account code length:", await ethers.provider.getCode(mockERC4337AccountAddress).then(code => code.length));
    console.log("Account implementation:", await accountFactory.accountImplementation());

    // Deploy factory for inheritance service
    const Factory = await ethers.getContractFactory("ERC7656Factory");
    factory = await Factory.deploy();
    await factory.waitForDeployment();

    // Deploy implementation
    const AccountInheritanceService = await ethers.getContractFactory("AccountInheritanceService");
    inheritanceServiceImpl = await AccountInheritanceService.deploy();
    await inheritanceServiceImpl.waitForDeployment();

    // Get addresses
    mockNFTAddress = await mockNFT.getAddress();
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
    await inheritanceService.initialize(await entryPoint.getAddress());

    // Fund the account with some ETH for gas
    await owner.sendTransaction({
      to: mockERC4337AccountAddress,
      value: ethers.parseEther("1.0")
    });

    // Stake some ETH in the entry point for the account
    await entryPoint.depositTo(mockERC4337AccountAddress, { value: ethers.parseEther("1.0") });

    return {
      inheritanceService,
      mockNFT,
      mockERC4337Account,
      entryPoint,
      owner: accountOwner, // Use the deterministic wallet as owner
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
  async function executeViaEntryPoint(account, target, data, signer) {
    // Create the user operation with defaults
    const userOp = fillUserOpDefaults({
      sender: await account.getAddress(),
      nonce: await entryPoint.getNonce(await account.getAddress(), 0),
      initCode: "0x",
      callData: data,
      verificationGasLimit: 300000,
      callGasLimit: 400000,
      preVerificationGas: 100000,
      maxFeePerGas: ethers.parseUnits("10", "gwei"),
      maxPriorityFeePerGas: ethers.parseUnits("5", "gwei"),
      paymaster: ethers.ZeroAddress,
      paymasterData: "0x",
      paymasterVerificationGasLimit: 0,
      paymasterPostOpGasLimit: 0,
      signature: "0x"
    });

    // Get the userOpHash using EIP-712 typed data
    const chainId = await ethers.provider.getNetwork().then(n => n.chainId);
    const userOpHash = getUserOpHash(userOp, await entryPoint.getAddress(), chainId);

    // Sign the hash using the official method (raw ECDSA signature without Ethereum prefix)
    const sig = ecsign(
      Buffer.from(ethers.getBytes(userOpHash)),
      Buffer.from(ethers.getBytes(signer.privateKey))
    );
    const signature = toRpcSig(sig.v, sig.r, sig.s);

    // Pack the user operation with the signature
    const packedUserOp = packUserOp({
      ...userOp,
      signature
    });

    try {
      // First simulate validation using MockEntryPointSimulations
      const MockEntryPointSimulations = await ethers.getContractFactory("MockEntryPointSimulations");
      const simulations = await MockEntryPointSimulations.deploy();
      await simulations.waitForDeployment();

      // Call simulateValidation through a static call
      const validationResult = await simulations.simulateValidation.staticCall(packedUserOp);
      console.log("Validation result:", validationResult);

      // If validation succeeds, execute the userOp through the entry point
      await entryPoint.handleOps([packedUserOp], await signer.getAddress());
    } catch (error) {
      console.error("Operation failed:", error);
      throw error;
    }
  }

  describe("Initialization", function () {
    it("should be deployed correctly", async function () {
      expect(await this.inheritanceService.getAddress()).to.be.properAddress;
    });

    it("should implement IERC7656Service", async function () {
      expect(await this.inheritanceService.supportsInterface("0x7e110a1d")).to.be.true;
    });

    it("should not allow double initialization", async function () {
      await expect(this.inheritanceService.initialize(await this.entryPoint.getAddress()))
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
    it.only("should allow setting up inheritance for an ERC-4337 account", async function () {
      const inheritanceDelay = 86400; // 1 day

      const setBeneficiaryData = this.inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await executeViaEntryPoint(
        this.mockERC4337Account,
        this.inheritanceServiceAddress,
        setBeneficiaryData,
        this.owner
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
        sender: this.mockERC4337AccountAddress,
        nonce: await this.entryPoint.getNonce(this.mockERC4337AccountAddress, 0),
        initCode: "0x",
        callData: executeData,
        accountGasLimits: ethers.solidityPacked(["uint128", "uint128"], [300000, 400000]),
        preVerificationGas: 50000,
        gasFees: ethers.solidityPacked(["uint128", "uint128"], [ethers.parseUnits("5", "gwei"), ethers.parseUnits("10", "gwei")]),
        paymasterAndData: "0x",
        signature: "0x"
      };

      // Sign the user operation with the other account (non-owner)
      const userOpHash = await this.entryPoint.getUserOpHash(userOp);
      const signature = await this.other.signMessage(ethers.getBytes(userOpHash));
      userOp.signature = "0x" + signature.slice(2);

      await expect(
        this.entryPoint.handleOps([userOp], this.other.address)
      ).to.be.revertedWithCustomError(this.entryPoint, "FailedOp");
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
        setBeneficiaryData,
        this.owner
      );

      // Mint NFT to the ERC-4337 account
      await this.mockNFT.mint(this.mockERC4337AccountAddress, 1);
    });

    it("should allow heir to claim inheritance after delay", async function () {
      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [86400]);
      await ethers.provider.send("evm_mine");

      // Create the execute call data
      const executeData = this.mockERC4337Account.interface.encodeFunctionData("execute", [
        this.mockERC4337AccountAddress,
        0,
        this.mockERC4337Account.interface.encodeFunctionData("setOwner", [this.heir.address])
      ]);

      // Create the user operation
      const userOp = {
        sender: this.mockERC4337AccountAddress,
        nonce: await this.entryPoint.getNonce(this.mockERC4337AccountAddress, 0),
        initCode: "0x",
        callData: executeData,
        accountGasLimits: ethers.solidityPacked(["uint128", "uint128"], [500000, 500000]),
        preVerificationGas: 50000,
        gasFees: ethers.solidityPacked(["uint128", "uint128"], [ethers.parseUnits("5", "gwei"), ethers.parseUnits("10", "gwei")]),
        paymasterAndData: "0x",
        signature: "0x"
      };

      // Get the user operation hash
      const userOpHash = await this.entryPoint.getUserOpHash(userOp);

      // Sign the user operation hash
      const signature = await this.owner.signMessage(ethers.getBytes(userOpHash));

      // Then we execute the claim through the service
      await expect(
        this.inheritanceService.connect(this.heir).claimAccount("0x" + signature.slice(2))
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
      await expect(
        this.inheritanceService.connect(this.heir).claimAccount("0x")
      ).to.be.revertedWithCustomError(this.inheritanceService, "GracePeriodNotExpired");
    });

    it("should not allow non-heir to claim inheritance", async function () {
      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [86400]);
      await ethers.provider.send("evm_mine");

      await expect(
        this.inheritanceService.connect(this.other).claimAccount("0x")
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
        setBeneficiaryData,
        this.owner
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
        setBeneficiaryData,
        this.owner
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
        this.entryPoint.handleOps([userOp], ethers.ZeroAddress)
      ).to.be.revertedWith("AA10 sender already constructed");
    });
  });

  describe("Signature Validation", function () {
    beforeEach(async function () {
      const inheritanceDelay = 86400;
      const setBeneficiaryData = this.inheritanceService.interface.encodeFunctionData("setBeneficiary", [
        this.heir.address,
        inheritanceDelay
      ]);

      await executeViaEntryPoint(
        this.mockERC4337Account,
        this.inheritanceServiceAddress,
        setBeneficiaryData,
        this.owner
      );

      await ethers.provider.send("evm_increaseTime", [inheritanceDelay + 1]);
      await ethers.provider.send("evm_mine");
    });

    it("should accept empty signature for testing", async function () {
      await expect(
        this.inheritanceService.connect(this.heir).claimAccount("0x")
      )
        .to.emit(this.inheritanceService, "AccountClaimed")
        .withArgs(
          this.mockERC4337AccountAddress,
          0,
          this.heir.address
        );
    });

    it("should accept valid signature from owner", async function () {
      // Create the execute call data
      const executeData = this.mockERC4337Account.interface.encodeFunctionData("execute", [
        this.mockERC4337AccountAddress,
        0,
        this.mockERC4337Account.interface.encodeFunctionData("setOwner", [this.heir.address])
      ]);

      // Create the user operation
      const userOp = {
        sender: this.mockERC4337AccountAddress,
        nonce: await this.entryPoint.getNonce(this.mockERC4337AccountAddress, 0),
        initCode: "0x",
        callData: executeData,
        accountGasLimits: ethers.solidityPacked(["uint128", "uint128"], [500000, 500000]),
        preVerificationGas: 50000,
        gasFees: ethers.solidityPacked(["uint128", "uint128"], [ethers.parseUnits("5", "gwei"), ethers.parseUnits("10", "gwei")]),
        paymasterAndData: "0x",
        signature: "0x"
      };

      // Get the user operation hash
      const userOpHash = await this.entryPoint.getUserOpHash(userOp);

      // Sign the user operation hash
      const signature = await this.owner.signMessage(ethers.getBytes(userOpHash));

      await expect(
        this.inheritanceService.connect(this.heir).claimAccount("0x" + signature.slice(2))
      )
        .to.emit(this.inheritanceService, "AccountClaimed")
        .withArgs(
          this.mockERC4337AccountAddress,
          0,
          this.heir.address
        );
    });

    it("should reject invalid signature", async function () {
      const invalidSignature = "0x" + "1".repeat(130);
      await expect(
        this.inheritanceService.connect(this.heir).claimAccount(invalidSignature)
      ).to.be.revertedWith("AA24 signature error");
    });
  });
});
