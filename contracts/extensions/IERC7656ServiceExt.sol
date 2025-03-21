// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC7656Service} from "../interfaces/IERC7656Service.sol";

/**
 * @title IERC7656ServiceExt.sol.sol
 */
interface IERC7656ServiceExt is IERC7656Service {
  /**
   * @notice Returns the chainId where the contract was deployed
   */
  function chainId() external view returns (uint256);

  /**
   * @notice Returns the mode of the link
   */
  function mode() external view returns (bytes12);

  /**
   * @notice Returns the address of the token contract
   */
  function linkedContract() external view returns (address);

  /**
   * @notice Returns the linkedId of the token
   */
  function linkedId() external view returns (uint256);

  /**
   * @notice Returns the salt used when creating the contract
   */
  function salt() external view returns (bytes32);

  /**
   * @notice Returns the implementation used when creating the contract
   */
  function implementation() external view returns (address);
}
