// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ITimeControllerGuardian} from "./ITimeControllerGuardian.sol";

// import "hardhat/console.sol";

/**
 * @dev Manages upgrade and cross-chain execution settings for accounts
 */
contract TimeControllerGuardian is ITimeControllerGuardian, TimelockController {
  error InvalidArguments();

  error MustCallThroughTimeController();

  modifier onlyThroughTimeController() {
    if (msg.sender != address(this)) revert MustCallThroughTimeController();
    _;
  }

  mapping(address => bool) private _trusted;

  // when deployed to production, proposers and executors will be multi-sig wallets owned by the Cruna DAO
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin
  ) TimelockController(minDelay, proposers, executors, admin) {}

  function version() public pure virtual returns (uint256) {
    return 1_000_000;
  }

  function trust(address implementation, bool trusted_) external onlyThroughTimeController {
    if (trusted_) {
      _trusted[implementation] = trusted_;
    } else {
      delete _trusted[implementation];
    }
    emit Trusted(implementation, trusted_);
  }

  function trusted(address implementation) external view returns (bool) {
    return _trusted[implementation];
  }
}
