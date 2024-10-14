// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IGuardian} from "../../IGuardian.sol";
// import "hardhat/console.sol";

/**
 * @dev Manages upgrade and cross-chain execution settings for accounts
 */
interface ITimeControllerGuardian is IGuardian {
  /**
   * @dev Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation.
   * All the values can be arbitrary, si there is no need for checking the input parameters.
   */
  function trust(address implementation, bool trusted) external;
}
