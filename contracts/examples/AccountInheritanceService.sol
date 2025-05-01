// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC7656Service} from "../ERC7656Service.sol";

interface IEntryPoint {
  struct UserOperation {
    address sender;
    uint256 value;
    bytes callData;
  }

  function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;
}

/**
 * @title AccountInheritanceService
 * @notice A service that allows an ERC-4337 account owner to designate a beneficiary who can claim the account
 * if the owner doesn't provide a proof of life within a specified timeframe
 */
contract AccountInheritanceService is ERC7656Service, Ownable {
  bytes12 private constant _NO_LINKED_ID = 0x000000000000000000000001;
  bool private _initialized;

  struct Inheritance {
    address beneficiary;
    uint256 lastProofOfLife;
    uint256 gracePeriod;
  }

  // Mapping from account address => inheritance data
  mapping(address => mapping(uint256 => Inheritance)) public inheritances;

  event BeneficiarySet(address indexed account, uint256 indexed id, address beneficiary);
  event ProofOfLifeProvided(address indexed account, uint256 indexed id);
  event AccountClaimed(address indexed account, uint256 indexed id, address beneficiary);

  error NotOwner();
  error NoBeneficiarySet();
  error GracePeriodNotExpired();
  error TransferFailed();
  error WrongChain();
  error WrongMode();
  error AlreadyInitialized();
  error NotInitialized();
  error EntryPointNotSet();

  // The entry point contract address
  address public entryPoint;

  modifier whenInitialized() {
    if (!_initialized) revert NotInitialized();
    _;
  }

  constructor() Ownable(msg.sender) {}

  /**
   * @notice Initialize the service by validating the mode and setting the entry point
   * @param _entryPoint The entry point contract address
   */
  function initialize(address _entryPoint) external {
    if (_initialized) revert AlreadyInitialized();
    (uint256 chainId, bytes12 mode, , ) = linkedData();
    if (chainId != block.chainid) revert WrongChain();
    if (mode != _NO_LINKED_ID) revert WrongMode();
    entryPoint = _entryPoint;
    _initialized = true;
  }

  /**
   * @notice Sets a beneficiary for the account
   * @param beneficiary The address that will receive the account if the owner doesn't provide proof of life
   * @param gracePeriod The time period (in seconds) after which the beneficiary can claim if no proof of life is provided
   */
  function setBeneficiary(address beneficiary, uint256 gracePeriod) external whenInitialized {
    (uint256 chainId, , address linkedContract, uint256 linkedId) = linkedData();
    if (chainId != block.chainid) revert WrongChain();

    if (msg.sender != linkedContract) revert NotOwner();

    inheritances[linkedContract][linkedId] = Inheritance({
      beneficiary: beneficiary,
      lastProofOfLife: block.timestamp,
      gracePeriod: gracePeriod
    });

    emit BeneficiarySet(linkedContract, linkedId, beneficiary);
  }

  /**
   * @notice Provides proof of life for the account
   */
  function provideProofOfLife() external whenInitialized {
    (uint256 chainId, , address linkedContract, uint256 linkedId) = linkedData();
    if (chainId != block.chainid) revert WrongChain();

    if (msg.sender != linkedContract) revert NotOwner();

    Inheritance storage inheritance = inheritances[linkedContract][linkedId];
    inheritance.lastProofOfLife = block.timestamp;

    emit ProofOfLifeProvided(linkedContract, linkedId);
  }

  /**
   * @notice Claims the account if the grace period has expired
   */
  function claimAccount() external whenInitialized {
    if (entryPoint == address(0)) revert EntryPointNotSet();
    (uint256 chainId, , address linkedContract, uint256 linkedId) = linkedData();
    if (chainId != block.chainid) revert WrongChain();

    Inheritance storage inheritance = inheritances[linkedContract][linkedId];
    if (inheritance.beneficiary == address(0)) revert NoBeneficiarySet();
    if (inheritance.beneficiary != msg.sender) revert NotOwner();

    if (block.timestamp <= inheritance.lastProofOfLife + inheritance.gracePeriod) {
      revert GracePeriodNotExpired();
    }

    // Create the transferOwnership call data
    bytes memory transferData = abi.encodeWithSignature("transferOwnership(address)", msg.sender);

    // Create the execute call data
    bytes memory executeData = abi.encodeWithSignature("execute(address,uint256,bytes)", linkedContract, 0, transferData);

    // Create the user operation
    IEntryPoint.UserOperation[] memory ops = new IEntryPoint.UserOperation[](1);
    ops[0] = IEntryPoint.UserOperation({sender: linkedContract, value: 0, callData: executeData});

    // Execute the operation through the entry point
    IEntryPoint(entryPoint).handleOps(ops, payable(address(0)));

    emit AccountClaimed(linkedContract, linkedId, msg.sender);
  }

  /**
   * @notice Returns the inheritance data for the account
   */
  function getInheritanceData() external view whenInitialized returns (Inheritance memory) {
    (uint256 chainId, , address linkedContract, uint256 linkedId) = linkedData();
    if (chainId != block.chainid) revert WrongChain();

    return inheritances[linkedContract][linkedId];
  }
}
