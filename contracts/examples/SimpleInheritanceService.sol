// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC7656Service} from "../ERC7656Service.sol";

/**
 * @title SimpleInheritanceService
 * @notice A service that allows an NFT owner to designate a beneficiary who can claim the NFT
 * if the owner doesn't provide a proof of life within a specified timeframe
 */
contract SimpleInheritanceService is ERC7656Service, Ownable {
  bytes12 private constant _LINKED_ID = 0x000000000000000000000000;
  bool private _initialized;

  struct Inheritance {
    address beneficiary;
    uint256 lastProofOfLife;
    uint256 gracePeriod;
  }

  // Mapping from NFT contract => token ID => inheritance data
  mapping(address => mapping(uint256 => Inheritance)) public inheritances;

  event BeneficiarySet(address indexed nftContract, uint256 indexed tokenId, address beneficiary);
  event ProofOfLifeProvided(address indexed nftContract, uint256 indexed tokenId);
  event NFTClaimed(address indexed nftContract, uint256 indexed tokenId, address beneficiary);

  error NotOwner();
  error NoBeneficiarySet();
  error GracePeriodNotExpired();
  error TransferFailed();
  error WrongChain();
  error WrongMode();
  error AlreadyInitialized();
  error NotInitialized();

  modifier whenInitialized() {
    if (!_initialized) revert NotInitialized();
    _;
  }

  constructor() Ownable(msg.sender) {}

  /**
   * @notice Initialize the service by validating the mode
   */
  function initialize() external {
    if (_initialized) revert AlreadyInitialized();
    (uint256 chainId, bytes12 mode, , ) = linkedData();
    if (chainId != block.chainid) revert WrongChain();
    if (mode != _LINKED_ID) revert WrongMode();
    _initialized = true;
  }

  /**
   * @notice Sets a beneficiary for the NFT
   * @param beneficiary The address that will receive the NFT if the owner doesn't provide proof of life
   * @param gracePeriod The time period (in seconds) after which the beneficiary can claim if no proof of life is provided
   */
  function setBeneficiary(address beneficiary, uint256 gracePeriod) external whenInitialized {
    (uint256 chainId, , address linkedContract, uint256 linkedId) = linkedData();
    if (chainId != block.chainid) revert WrongChain();

    address owner = IERC721(linkedContract).ownerOf(linkedId);
    if (msg.sender != owner) revert NotOwner();

    inheritances[linkedContract][linkedId] = Inheritance({
      beneficiary: beneficiary,
      lastProofOfLife: block.timestamp,
      gracePeriod: gracePeriod
    });

    emit BeneficiarySet(linkedContract, linkedId, beneficiary);
  }

  /**
   * @notice Provides proof of life for the NFT
   */
  function provideProofOfLife() external whenInitialized {
    (uint256 chainId, , address linkedContract, uint256 linkedId) = linkedData();
    if (chainId != block.chainid) revert WrongChain();

    address owner = IERC721(linkedContract).ownerOf(linkedId);
    if (msg.sender != owner) revert NotOwner();

    Inheritance storage inheritance = inheritances[linkedContract][linkedId];
    inheritance.lastProofOfLife = block.timestamp;

    emit ProofOfLifeProvided(linkedContract, linkedId);
  }

  /**
   * @notice Claims the NFT if the grace period has expired
   */
  function claimNFT() external whenInitialized {
    (uint256 chainId, , address linkedContract, uint256 linkedId) = linkedData();
    if (chainId != block.chainid) revert WrongChain();

    Inheritance storage inheritance = inheritances[linkedContract][linkedId];
    if (inheritance.beneficiary == address(0)) revert NoBeneficiarySet();
    if (inheritance.beneficiary != msg.sender) revert NotOwner();

    if (block.timestamp <= inheritance.lastProofOfLife + inheritance.gracePeriod) {
      revert GracePeriodNotExpired();
    }

    // Transfer the NFT to the beneficiary
    IERC721(linkedContract).transferFrom(address(this), msg.sender, linkedId);

    emit NFTClaimed(linkedContract, linkedId, msg.sender);
  }

  /**
   * @notice Returns the inheritance data for the NFT
   */
  function getInheritanceData() external view whenInitialized returns (Inheritance memory) {
    (uint256 chainId, , address linkedContract, uint256 linkedId) = linkedData();
    if (chainId != block.chainid) revert WrongChain();

    return inheritances[linkedContract][linkedId];
  }
}
