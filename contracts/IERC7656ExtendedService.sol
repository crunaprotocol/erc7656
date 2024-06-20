// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC7656Service} from "./IERC7656Service.sol";
import {EIP5313} from "./utils/EIP5313.sol";

// this is a reduction of IERC6551Account focusing purely on the bond between the NFT and the contract

/**
 * @title IERC7656ExtendedService.sol.sol
 */
interface IERC7656ExtendedService is IERC7656Service, EIP5313 {
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
