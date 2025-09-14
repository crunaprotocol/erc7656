// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@account-abstraction/contracts/accounts/SimpleAccount.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";

/**
 * @title MockERC4337Account
 * @notice A mock ERC-4337 account for testing purposes that extends the standard SimpleAccount
 */
contract MockERC4337Account is SimpleAccount {
  constructor(IEntryPoint anEntryPoint) SimpleAccount(anEntryPoint) {}

  /**
   * @notice Initialize the account with an owner
   * @param anOwner The owner of the account
   */
  function initialize(address anOwner) public override initializer {
    super.initialize(anOwner);
  }

  /**
   * @notice Get the entry point contract
   * @return The entry point contract
   */
  function entryPoint() public view override returns (IEntryPoint) {
    return super.entryPoint();
  }

  /**
   * @notice Validate a user operation signature
   * @param userOp The user operation to validate
   * @param userOpHash The hash of the user operation
   * @return validationData The validation data
   */
  function _validateSignature(
    PackedUserOperation calldata userOp,
    bytes32 userOpHash
  ) internal override returns (uint256 validationData) {
    return super._validateSignature(userOp, userOpHash);
  }
}
