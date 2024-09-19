// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {ERC7656ServiceExt} from "../../extensions/ERC7656ServiceExt.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {IGuardian} from "../../utils/guardians/IGuardian.sol";

//import "hardhat/console.sol";

contract SimpleERC20Wallet is ERC7656ServiceExt, ReentrancyGuard {
  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  uint256[50] private __gap;
}
