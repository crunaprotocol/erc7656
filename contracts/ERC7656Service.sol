// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC7656ServiceLib} from "./lib/ERC7656ServiceLib.sol";

import {IERC7656Service} from "./interfaces/IERC7656Service.sol";

//import "hardhat/console.sol";

/**
 * @title ERC7656Service.sol.sol
 * @notice Abstract contract to link a contract to an NFT
 */
contract ERC7656Service is IERC7656Service, IERC165 {
  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return interfaceId == type(IERC7656Service).interfaceId;
  }

  /**
   * @notice Returns the linkedContract linked to the contract
   */
  function linkedData() public view virtual override returns (uint256, bytes12, address, uint256) {
    return _linkedData();
  }

  /**
   * Private functions
   */

  function _linkedData() internal view returns (uint256, bytes12, address, uint256) {
    return ERC7656ServiceLib.linkedData(address(this));
  }

  // @dev This empty reserved space is put in place to allow future versions
  // to add new variables without shifting down storage in the inheritance
  // chain when writing upgradeable contracts.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
