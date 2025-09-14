const {expect} = require("chai");
const {ethers} = require("hardhat");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();
const bytecodes = require("../contracts/bytecode.json");
const {anyValue} = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

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

  let factory, factoryExt;
  let deployer, bob, alice, fred, mark;
  let chainId, chainIdBytes32;
  let badgeCollectorImpl, nft;
  let magicBadge, collBadge, superTransferableBadge;
  let badgeCollector;
  const salt = "0x" + "aabbccdd".repeat(8);

  let linkedId = Number(1).toString(16).padStart(64, "0");
  let erc1167Constructor = "0x3d60ad80600a3d3981f3";
  let erc1167Header = "0x363d3d373d3d3d363d73";
  let erc1167ConstructorPlusHeader = erc1167Constructor + de0x(erc1167Header);
  let erc1167Footer = "0x5af43d82803e903d91602b57fd5bf3"
  let contractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  let implAddress = "0x0B306BF915C4d645ff596e518fAf3F9669b97016";
  let mode1 = "0x000000000000000000000001";
  let mode0 = "0x000000000000000000000000";

  before(async function () {
    [deployer, bob, alice, fred, mark] = await ethers.getSigners();
    await deployUtils.deployNickSFactory(deployer);

    chainId = await getChainId();
    chainIdBytes32 = "0x" + chainId.toString(16).padStart(64, "0");

    factory = await deployUtils.deployBytecodeViaNickSFactory(
        deployer,
        "ERC7656Factory",
        bytecodes.bytecode,
        bytecodes.salt,
    );
    const registryAddress = await factory.getAddress();
    expect(registryAddress).equal(bytecodes.address);

    factoryExt = await deployUtils.deploy("ERC7656FactoryExt");

    expect(await getInterfaceId("IERC7656Factory")).equal("9e23230a");
    expect(await getInterfaceId("IERC7656Service")).equal("7e110a1d");
    expect(await getInterfaceId("IERC165")).equal("01ffc9a7");

    expect(await factory.supportsInterface("0x9e23230a")).equal(true);
    expect(await factory.supportsInterface("0x01ffc9a7")).equal(true);
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

  it("should get the expected creation code", async function () {

    let bytecode = await factoryExt.getCreationBytecode(
        implAddress,
        salt,
        chainIdBytes32,
        mode1, // mode
        contractAddress,
        '0x00' // it is ignored
    );
    expect(bytecode).equal(
        (erc1167ConstructorPlusHeader +
        de0x(implAddress) +
        de0x(erc1167Footer) +
        de0x(salt) +
        de0x(chainIdBytes32) +
        de0x(mode1) +
        de0x(contractAddress) +
        "00".repeat(32)
        ).toLowerCase());

    bytecode = await factoryExt.getCreationBytecode(
        implAddress,
        salt,
        chainIdBytes32,
        mode0, // mode
        contractAddress,
        '0x1234' // it is ignored
    );
    expect(bytecode).equal(
        (erc1167ConstructorPlusHeader +
            de0x(implAddress) +
            de0x(erc1167Footer) +
            de0x(salt) +
            de0x(chainIdBytes32) +
            de0x(mode0) +
            de0x(contractAddress) +
        "00".repeat(30) + "1234"
    ).toLowerCase());

  });

  it("should associate the service to the NFT and verify that the service has been deployed", async function () {

    // Compute the address first
    let expectedServiceAddress = await factory.compute(
        implAddress,
        salt,
        chainIdBytes32,
        mode0,
        contractAddress,
        linkedId
    );

    try {
      // Create the service using the same ID
      const tx = await factory.create(
          implAddress,
          salt,
          chainIdBytes32,
          mode0,
          contractAddress,
          linkedId,  // Use the same ID here
          { gasLimit: 500000 }
      );
      const receipt = await tx.wait();
      // console.log("Transaction receipt logs:", receipt.logs);
    } catch (error) {
      console.error("Error details:", error);
      throw error;  // Re-throw to fail the test
    }

    // Verify the address has code
    let code = await ethers.provider.getCode(expectedServiceAddress);
    // console.log("Code at address:", code);
    expect(code).equal(
        (erc1167Header +
            de0x(implAddress) +
            de0x(erc1167Footer) +
            de0x(salt) +
            de0x(chainIdBytes32) +
            de0x(mode0) +
            de0x(contractAddress) +
            de0x(linkedId)
        ).toLowerCase()
    );

    let computedAddress = await factoryExt.getComputedAddress(salt, (erc1167ConstructorPlusHeader +
        de0x(implAddress) +
        de0x(erc1167Footer) +
        de0x(salt) +
        de0x(chainIdBytes32) +
        de0x(mode0) +
        de0x(contractAddress) +
        de0x(linkedId)
    ).toLowerCase(), await factory.getAddress());
    expect(computedAddress).equal(expectedServiceAddress);

    // test the case the contract has been already deployed

    await factory.create(
        implAddress,
        salt,
        chainIdBytes32,
        mode0,
        contractAddress,
        linkedId,  // Use the same ID here
        { gasLimit: 500000 }
    );
  });

  it("should associate the service to the NFT and verify that the service has been deployed using the extended contract, to get a right coverage", async function () {

    expect(await factoryExt.supportsInterface("0x9e23230a")).equal(true);
    expect(await factoryExt.supportsInterface("0x01ffc9a7")).equal(true);

    // Compute the address first
    let expectedServiceAddress = await factoryExt.compute(
        implAddress,
        salt,
        chainIdBytes32,
        mode0,
        contractAddress,
        linkedId
    );

    try {
      // Create the service using the same ID
      const tx = await factoryExt.create(
          implAddress,
          salt,
          chainIdBytes32,
          mode0,
          contractAddress,
          linkedId,  // Use the same ID here
          { gasLimit: 500000 }
      );
      const receipt = await tx.wait();
      // console.log("Transaction receipt logs:", receipt.logs);
    } catch (error) {
      console.error("Error details:", error);
      throw error;  // Re-throw to fail the test
    }

    // Verify the address has code
    let code = await ethers.provider.getCode(expectedServiceAddress);
    // console.log("Code at address:", code);
    expect(code).equal(
        (erc1167Header +
            de0x(implAddress) +
            de0x(erc1167Footer) +
            de0x(salt) +
            de0x(chainIdBytes32) +
            de0x(mode0) +
            de0x(contractAddress) +
            de0x(linkedId)
        ).toLowerCase()
    );

    let computedAddress = await factoryExt.getComputedAddress(salt, (erc1167ConstructorPlusHeader +
        de0x(implAddress) +
        de0x(erc1167Footer) +
        de0x(salt) +
        de0x(chainIdBytes32) +
        de0x(mode0) +
        de0x(contractAddress) +
        de0x(linkedId)
    ).toLowerCase(), await factoryExt.getAddress());
    expect(computedAddress).equal(expectedServiceAddress);

    // test the case the contract has been already deployed

    await factoryExt.create(
        implAddress,
        salt,
        chainIdBytes32,
        mode0,
        contractAddress,
        linkedId,  // Use the same ID here
        { gasLimit: 500000 }
    );
  });

  function de0x(value) {
    return value.replace(/^0x/, "");
  }

  it("should associate the service to a smart account and verify that the service has been deployed", async function () {

    // Compute the address first
    let expectedServiceAddress = await factory.compute(
        implAddress,
        salt,
        chainIdBytes32,
        mode1,
        contractAddress,
        1234
    );

    try {
      // Create the service using the same ID
      const tx = await factory.create(
          implAddress,
          salt,
          chainIdBytes32,
          mode1,
          contractAddress,
          1234,
          { gasLimit: 500000 }
      );
      const receipt = await tx.wait();
      // console.log("Transaction receipt logs:", receipt.logs);
    } catch (error) {
      console.error("Error details:", error);
      throw error;  // Re-throw to fail the test
    }

    // Verify the address has code
    let serviceAddress = expectedServiceAddress;
    let code = await ethers.provider.getCode(serviceAddress);
    // console.log("Code at address:", code);
    expect(code).equal("0x363d3d373d3d3d363d730b306bf915c4d645ff596e518faf3f9669b970165af43d82803e903d91602b57fd5bf3aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd0000000000000000000000000000000000000000000000000000000000007a69000000000000000000000001e7f1725e7734ce288f8367e1bb143e90bb3f051200000000000000000000000000000000000000000000000000000000000004d2");
  });


    it("should associate the service to the NFT and verify that the service has been deployed and works", async function () {

    let linkedId = 1;
    // mint an nft
    await nft.safeMint(bob.address, linkedId);

      let expectedServiceAddress = await factory.compute(
          await badgeCollectorImpl.getAddress(),
          salt,
          chainIdBytes32,
          mode0,
          await nft.getAddress(),
          linkedId
      );

      await expect(factory.create(
            await badgeCollectorImpl.getAddress(),
            salt,
            chainIdBytes32,
            mode0,
            await nft.getAddress(),
            linkedId,  // Use the same ID here
            { gasLimit: 500000 }
        )).emit(factory, "Created")
          .withArgs(
              expectedServiceAddress,
              await badgeCollectorImpl.getAddress(),
              salt,
              chainIdBytes32,
              mode0,
              await nft.getAddress(),
              linkedId
          );

    badgeCollector = await deployUtils.getContract("BadgeCollectorService", expectedServiceAddress);

    expect(await badgeCollector.supportsInterface("0x7e110a1d")).equal(true);

    expect(await badgeCollector.owner()).equal(bob.address);
    const linkedData = await badgeCollector.linkedData();

    expect(linkedData[0]).equal(chainId);
    expect(linkedData[1]).equal(mode0);
    expect(linkedData[2]).equal(await nft.getAddress());
    expect(linkedData[3]).equal(linkedId);

    expect(await badgeCollector.salt()).equal(salt);
    expect(await badgeCollector.chainId()).equal(chainId);
    expect(await badgeCollector.mode()).equal(mode0);
    expect(await badgeCollector.linkedContract()).equal(await nft.getAddress());
    expect(await badgeCollector.linkedId()).equal(linkedId);
    expect(await badgeCollector.implementation()).equal(await badgeCollectorImpl.getAddress());
  });

  it("should use and verify the service", async function () {

    let linkedId = 1;
    // mint an nft
    await nft.safeMint(bob.address, linkedId);

    let expectedServiceAddress = await factory.compute(
        await badgeCollectorImpl.getAddress(),
        salt,
        chainIdBytes32,
        mode0,
        await nft.getAddress(),
        linkedId
    );

    await factory.create(
        await badgeCollectorImpl.getAddress(),
        salt,
        chainIdBytes32,
        mode0,
        await nft.getAddress(),
        linkedId,  // Use the same ID here
        { gasLimit: 500000 }
    );

    badgeCollector = await deployUtils.getContract("BadgeCollectorService", expectedServiceAddress);

    expect(await badgeCollector.owner()).equal(bob.address);

    badgeCollector = await deployUtils.getContract("BadgeCollectorService", expectedServiceAddress);

    await expect(collBadge.safeMint(expectedServiceAddress, linkedId)).emit(collBadge, "Transfer").withArgs(addr0, expectedServiceAddress, linkedId);

    await expect(magicBadge.safeMint(expectedServiceAddress, linkedId)).emit(magicBadge, "Transfer").withArgs(addr0, expectedServiceAddress, linkedId);

    await expect(superTransferableBadge.safeMint(expectedServiceAddress, linkedId))
        .emit(superTransferableBadge, "Transfer")
        .withArgs(addr0, expectedServiceAddress, linkedId);

    await assertThrowsMessage(badgeCollector.connect(bob).transferBadgeToOwner(await collBadge.getAddress(), linkedId), "NotTransferable");

    await expect(badgeCollector.connect(bob).transferBadgeToOwner(await superTransferableBadge.getAddress(), linkedId))
        .emit(superTransferableBadge, "Transfer")
        .withArgs(expectedServiceAddress, bob.address, linkedId);

    expect(await superTransferableBadge.firstOwnerOf(linkedId)).equal(expectedServiceAddress);
  });

});
