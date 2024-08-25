// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockPlugin {
  error AlreadyInitialized();

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function initialize(address _owner) external {
    if (owner != address(0)) revert AlreadyInitialized();
    owner = _owner;
  }
}
