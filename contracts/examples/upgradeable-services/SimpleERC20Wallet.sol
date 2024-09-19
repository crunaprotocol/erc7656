// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {ERC7656ServiceExt} from "../../extensions/ERC7656ServiceExt.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {IGuardian} from "../../utils/guardians/IGuardian.sol";

//import "hardhat/console.sol";

contract SimpleERC20Wallet is ERC7656ServiceExt, ReentrancyGuard {
  error ZeroAddress();
  error NotTheFactory();
  error UnauthorizedUpgrade();
  error UntrustedImplementation();
  error Unauthorized();
  error InvalidVersion(uint256 oldVersion, uint256 newVersion);
  error AlreadyInitiated();

  IGuardian public guardian;

  /**
   * @notice Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  function init(address _guardian) public {
    if (msg.sender != tokenAddress()) revert Unauthorized();
    if (address(guardian) != address(0)) revert AlreadyInitiated();
    if (_guardian == address(0)) revert ZeroAddress();
    guardian = IGuardian(_guardian);
  }

  /**
   * @notice Upgrades the implementation of the plugin
   * @param implementation_ The new implementation
   */
  function upgrade(address implementation_) external virtual nonReentrant {
    if (owner() != msg.sender) revert UnauthorizedUpgrade();
    if (implementation_ == address(0)) revert ZeroAddress();
    if (!IGuardian(guardian).trusted(implementation_)) revert UntrustedImplementation();

    // It would be good to check the version of the implementation, for example
    // to avoid downgrades if the storage was changed in the new implementation

    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  uint256[50] private __gap;
}
