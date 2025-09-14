// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@account-abstraction/contracts/core/EntryPointSimulations.sol";

/**
 * @title MockEntryPointSimulations
 * @notice A mock contract that extends EntryPointSimulations for testing purposes
 * @dev This contract exists only to make the EntryPointSimulations contract available in Hardhat tests
 */
contract MockEntryPointSimulations is EntryPointSimulations {
    // Override the constructor to allow deployment in tests
    constructor() {
        // Skip the block number check in the parent constructor
    }
} 