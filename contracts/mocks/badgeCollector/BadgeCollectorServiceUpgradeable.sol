// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {IERC7656ServiceExt} from "../../extensions/ERC7656ServiceExt.sol";
import {Guardian} from "../Guardian.sol";
import {BadgeCollectorService} from "./BadgeCollectorService.sol";

contract BadgeCollectorServiceUpgradeable is BadgeCollectorService {
  /**
   * @notice Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  error NotTheGuardianSetter();
  error GuardianAlreadySet();
  error NotTrustedImplementation();
  error InvalidPluginVersion(uint256 oldVersion, uint256 newVersion);
  error PluginRequiresNewerManager(uint256 requiredVersion);
  error ZeroAddress();

  // It is the plugin's responsibility to be sure that the new implementation is trusted
  function upgrade(address implementation_) external virtual {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (implementation_ == address(0)) revert ZeroAddress();
    // hardcoded because deployed, in this example, via Nick's factory
    Guardian guardian = Guardian(0x7F26e4102B43c247252dD3bE6ABeD4E096d95b95);
    bool trusted = guardian.trusted(implementation_);
    if (!trusted) revert NotTrustedImplementation();
    IERC7656ServiceExt impl = IERC7656ServiceExt(implementation_);
    uint256 version_ = impl.version();
    if (version_ <= _version()) revert InvalidPluginVersion(_version(), version_);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
