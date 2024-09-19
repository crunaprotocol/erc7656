// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IGuardian} from "../../IGuardian.sol";
import {SimpleTimeController} from "../../../SimpleTimeController.sol";

/**
 * @title ISimpleTimeControllerGuardian.sol.sol
 * @notice Manages upgrade and cross-chain execution settings for accounts
 */
interface ISimpleTimeControllerGuardian is IGuardian {
  /**
   * @notice Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation.
   * @param delay The delay for the operation
   * @param oType The type of operation
   * @param implementation The address of the implementation
   * @param trusted_ When true, it set the implementation as trusted, when false it removes the implementation from the trusted list
   * Notice that for managers requires will always be 1
   */
  function trust(uint256 delay, SimpleTimeController.OperationType oType, address implementation, bool trusted_) external;
}
