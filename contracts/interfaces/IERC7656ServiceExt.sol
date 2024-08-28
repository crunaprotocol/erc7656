// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC7656Service} from "./IERC7656Service.sol";
// this is a reduction of IERC6551Account focusing purely on the bond between the NFT and the contract

/**
 * @title IERC7656ServiceExt.sol.sol
 */
interface IERC7656ServiceExt is IERC7656Service {
  /**
   * @notice Returns the address of the token contract
   */
  function tokenAddress() external view returns (address);

  /**
   * @notice Returns the salt used when creating the contract
   */
  function salt() external view returns (bytes32);

  /**
   * @notice Returns the tokenId of the token
   */
  function tokenId() external view returns (uint256);

  /**
   * @notice Returns the implementation used when creating the contract
   */
  function implementation() external view returns (address);
}
