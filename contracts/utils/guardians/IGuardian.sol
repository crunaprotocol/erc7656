// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IGuardian.sol
 * @notice Manages upgrade and cross-chain execution settings for accounts
 */
interface IGuardian {
  /**
   * @notice Emitted when a trusted implementation is updated
   * @param implementation The address of the implementation
   * @param trusted Whether the implementation is marked as a trusted or marked as no more trusted
   */
  event Trusted(address indexed implementation, bool trusted);

  /**
   * @notice Error returned when the arguments are invalid
   */
  error InvalidArgument();

  /// @notice A trust function must be implemented by extending interfaces

  /**
   * @notice Returns the manager version required by a trusted implementation
   * @param implementation The address of the implementation
   * @return True if a trusted implementation
   */
  function trusted(address implementation) external view returns (bool);
}
