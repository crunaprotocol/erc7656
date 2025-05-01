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
    bytes12 constant LINKED_ID = 0x000000000000000000000000;

    struct Inheritance {
        address beneficiary;
        uint256 lastProofOfLife;
        uint256 gracePeriod;
    }

    // Mapping from NFT contract address => tokenId => inheritance data
    mapping(address => mapping(uint256 => Inheritance)) public inheritances;

    event BeneficiarySet(address indexed nftContract, uint256 indexed tokenId, address beneficiary);
    event ProofOfLifeProvided(address indexed nftContract, uint256 indexed tokenId);
    event NFTClaimed(address indexed nftContract, uint256 indexed tokenId, address beneficiary);

    error NotOwner();
    error NoBeneficiarySet();
    error GracePeriodNotExpired();
    error TransferFailed();
    error WrongMode();

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Sets a beneficiary for the NFT
     * @param beneficiary The address that will receive the NFT if the owner doesn't provide proof of life
     * @param gracePeriod The time period (in seconds) after which the beneficiary can claim if no proof of life is provided
     */
    function setBeneficiary(address beneficiary, uint256 gracePeriod) external {
        (uint256 chainId, bytes12 mode, address linkedContract, uint256 linkedId) = linkedData();
        if (chainId != block.chainid) revert("Wrong chain");
        if (mode != LINKED_ID) revert WrongMode();
        
        address owner = IERC721(linkedContract).ownerOf(linkedId);
        if (owner != msg.sender) revert NotOwner();

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
    function provideProofOfLife() external {
        (uint256 chainId, bytes12 mode, address linkedContract, uint256 linkedId) = linkedData();
        if (chainId != block.chainid) revert("Wrong chain");
        if (mode != LINKED_ID) revert WrongMode();
        
        address owner = IERC721(linkedContract).ownerOf(linkedId);
        if (owner != msg.sender) revert NotOwner();

        Inheritance storage inheritance = inheritances[linkedContract][linkedId];
        inheritance.lastProofOfLife = block.timestamp;

        emit ProofOfLifeProvided(linkedContract, linkedId);
    }

    /**
     * @notice Claims the NFT if the grace period has expired
     */
    function claimNFT() external {
        (uint256 chainId, bytes12 mode, address linkedContract, uint256 linkedId) = linkedData();
        if (chainId != block.chainid) revert("Wrong chain");
        if (mode != LINKED_ID) revert WrongMode();

        Inheritance storage inheritance = inheritances[linkedContract][linkedId];
        if (inheritance.beneficiary == address(0)) revert NoBeneficiarySet();
        if (inheritance.beneficiary != msg.sender) revert NotOwner();

        if (block.timestamp <= inheritance.lastProofOfLife + inheritance.gracePeriod) {
            revert GracePeriodNotExpired();
        }

        address owner = IERC721(linkedContract).ownerOf(linkedId);
        IERC721(linkedContract).transferFrom(owner, msg.sender, linkedId);

        emit NFTClaimed(linkedContract, linkedId, msg.sender);
    }

    /**
     * @notice Returns the inheritance data for the NFT
     */
    function getInheritanceData() external view returns (Inheritance memory) {
        (uint256 chainId, bytes12 mode, address linkedContract, uint256 linkedId) = linkedData();
        if (chainId != block.chainid) revert("Wrong chain");
        if (mode != LINKED_ID) revert WrongMode();
        
        return inheritances[linkedContract][linkedId];
    }
} 