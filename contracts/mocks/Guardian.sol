// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.0;

/** @notice Minimalistic guardian to trust plugins implementations.
 * In real world usages, it would be better to use a governed, time controlled guardian
 */
contract Guardian {
  address public owner;
  mapping(address => bool) private _trusted;

  event Trusted(address indexed implementation);
  error NotAuthorized();
  error AlreadyInitialized();

  // Remove the constructor and replace it with an initialize function
  function initialize(address owner_) public {
    if (owner == address(0)) {
      owner = owner_;
    } else revert AlreadyInitialized();
  }

  function trust(address implementation) external {
    if (msg.sender != owner) revert NotAuthorized();
    _trusted[implementation] = true;
    emit Trusted(implementation);
  }

  function trusted(address implementation) external view returns (bool) {
    return _trusted[implementation];
  }

  uint256[50] private __gap;
}
