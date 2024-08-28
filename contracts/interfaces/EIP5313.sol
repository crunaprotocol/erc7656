// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EIP-5313 Light Contract Ownership Standard
 */
interface EIP5313 {
  /**
   * @notice Get the address of the owner
   *         In this specific case, it is the owner of the token
   * @return The address of the owner
   */
  function owner() external view returns (address);
}
