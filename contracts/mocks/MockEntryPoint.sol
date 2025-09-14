// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";

/**
 * @title MockEntryPoint
 * @notice A wrapper around the standard EntryPoint contract for testing purposes
 * @dev This contract exists only to make the EntryPoint contract available in Hardhat tests
 */
contract MockEntryPoint is EntryPoint {
  // No additional functionality needed - we just need to make the EntryPoint available in tests
}
