// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC7656Service} from "../interfaces/IERC7656Service.sol";

/**
 * @title IERC7656ServiceExt.sol.sol
 */
interface IERC7656ServiceExt is IERC7656Service {
  /**
   * @notice Returns the address of the token contract
   */
  function tokenAddress() external view returns (address);

  /**
   * @notice Returns the tokenId of the token
   */
  function tokenId() external view returns (uint256);

  /**
   * @notice Returns the salt used when creating the contract
   */
  function salt() external view returns (bytes32);

  /**
   * @notice Returns the implementation used when creating the contract
   */
  function implementation() external view returns (address);

  /**
   * @notice Returns the version of the contract.
   * The format is similar to semver, where any element takes 3 digits.
   * For example, version 1.2.14 is 1_002_014.
   * For simplicity, it does not include extra words like alpha, rc, etc. That can be set as a separate function, if needed.
   */
  function version() external pure returns (uint256);
}
