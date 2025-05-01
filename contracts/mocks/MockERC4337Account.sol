// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SimpleAccount} from "@account-abstraction/contracts/accounts/SimpleAccount.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title MockERC4337Account
 * @notice A mock ERC4337 account that extends the official SimpleAccount implementation
 */
contract MockERC4337Account is SimpleAccount {
  error NotOwner();

  constructor(IEntryPoint _entryPoint) SimpleAccount(_entryPoint) {}

  /**
   * @notice Transfer account ownership (only callable by the account itself or through the entry point)
   * @param newOwner The new owner address
   */
  function transferOwnership(address newOwner) external {
    if (msg.sender != address(this) && msg.sender != address(entryPoint())) revert NotOwner();
    owner = newOwner;
  }
}
