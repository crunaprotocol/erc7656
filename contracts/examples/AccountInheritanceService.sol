// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC7656Service} from "../ERC7656Service.sol";

/**
 * @title AccountInheritanceService
 * @notice A service that allows an ERC-4337 account owner to designate a beneficiary who can claim the account
 * if the owner doesn't provide a proof of life within a specified timeframe
 */
contract AccountInheritanceService is ERC7656Service, Ownable {
    bytes12 constant NO_LINKED_ID = 0x000000000000000000000001;

    struct Inheritance {
        address beneficiary;
        uint256 lastProofOfLife;
        uint256 gracePeriod;
    }

    // Mapping from account address => inheritance data
    mapping(address => Inheritance) public inheritances;

    event BeneficiarySet(address indexed account, address beneficiary);
    event ProofOfLifeProvided(address indexed account);
    event AccountClaimed(address indexed account, address beneficiary);

    error NotOwner();
    error NoBeneficiarySet();
    error GracePeriodNotExpired();
    error TransferFailed();
    error WrongMode();

    constructor() Ownable(msg.sender) {}

    /**
     * @notice Sets a beneficiary for the account
     * @param beneficiary The address that will receive the account if the owner doesn't provide proof of life
     * @param gracePeriod The time period (in seconds) after which the beneficiary can claim if no proof of life is provided
     */
    function setBeneficiary(address beneficiary, uint256 gracePeriod) external {
        (uint256 chainId, bytes12 mode, address linkedContract,) = linkedData();
        if (chainId != block.chainid) revert("Wrong chain");
        if (mode != NO_LINKED_ID) revert WrongMode();

        if (msg.sender != linkedContract) revert NotOwner();

        inheritances[linkedContract] = Inheritance({
            beneficiary: beneficiary,
            lastProofOfLife: block.timestamp,
            gracePeriod: gracePeriod
        });

        emit BeneficiarySet(linkedContract, beneficiary);
    }

    /**
     * @notice Provides proof of life for the account
     */
    function provideProofOfLife() external {
        (uint256 chainId, bytes12 mode, address linkedContract,) = linkedData();
        if (chainId != block.chainid) revert("Wrong chain");
        if (mode != NO_LINKED_ID) revert WrongMode();

        if (msg.sender != linkedContract) revert NotOwner();

        Inheritance storage inheritance = inheritances[linkedContract];
        inheritance.lastProofOfLife = block.timestamp;

        emit ProofOfLifeProvided(linkedContract);
    }

    /**
     * @notice Claims the account if the grace period has expired
     */
    function claimAccount() external {
        (uint256 chainId, bytes12 mode, address linkedContract, ) = linkedData();
        if (chainId != block.chainid) revert("Wrong chain");
        if (mode != NO_LINKED_ID) revert WrongMode();

        Inheritance storage inheritance = inheritances[linkedContract];
        if (inheritance.beneficiary == address(0)) revert NoBeneficiarySet();
        if (inheritance.beneficiary != msg.sender) revert NotOwner();

        if (block.timestamp <= inheritance.lastProofOfLife + inheritance.gracePeriod) {
            revert GracePeriodNotExpired();
        }

        // Call the account's transferOwnership function
        (bool success, ) = linkedContract.call(
            abi.encodeWithSignature("transferOwnership(address)", msg.sender)
        );
        if (!success) revert TransferFailed();

        emit AccountClaimed(linkedContract, msg.sender);
    }

    /**
     * @notice Returns the inheritance data for the account
     */
    function getInheritanceData() external view returns (Inheritance memory) {
        (uint256 chainId, bytes12 mode, address linkedContract, ) = linkedData();
        if (chainId != block.chainid) revert("Wrong chain");
        if (mode != NO_LINKED_ID) revert WrongMode();

        return inheritances[linkedContract];
    }
}
