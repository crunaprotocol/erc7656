// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOwnableGuardian} from "./IOwnableGuardian.sol";

/// @notice Minimalistic guardian to trust plugins implementations
contract OwnableGuardian is IOwnableGuardian, Ownable {
  mapping(address => bool) private _trusted;

  constructor(address admin) Ownable(admin) {}

  function trust(address implementation, bool trusted_) external onlyOwner {
    if (trusted_) {
      if (_trusted[implementation]) revert InvalidArgument();
    } else if (!_trusted[implementation]) revert InvalidArgument();
    if (trusted_) _trusted[implementation] = trusted_;
    else delete _trusted[implementation];
    emit Trusted(implementation, trusted_);
  }

  function trusted(address implementation) external view returns (bool) {
    return _trusted[implementation];
  }

  uint256[50] private __gap;
}
