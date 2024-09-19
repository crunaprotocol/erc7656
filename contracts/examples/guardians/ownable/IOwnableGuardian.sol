// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IGuardian} from "../IGuardian.sol";

/**
 * @title IOwnableGuardian.sol
 * @notice Manages upgrade and cross-chain execution settings for accounts
 */
interface IOwnableGuardian is IGuardian {
  /**
   * @notice Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation.
   * @param implementation The address of the implementation
   * @param trusted When true, it set the implementation as trusted, when false it removes the implementation from the trusted list
   * Notice that for managers requires will always be 1
   */
  function trust(address implementation, bool trusted) external;
}
