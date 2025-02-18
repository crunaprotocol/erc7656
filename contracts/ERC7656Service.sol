// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SimplifiedERC6551AccountLib} from "./lib/SimplifiedERC6551AccountLib.sol";

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
   * @notice Returns the token linked to the contract
   */
  function token() public view virtual override returns (uint256, address, uint256) {
    return _token();
  }

  /**
   * Private functions
   */

  function _token() internal view returns (uint256, address, uint256) {
    return SimplifiedERC6551AccountLib.token();
  }

  // @dev This empty reserved space is put in place to allow future versions
  // to add new variables without shifting down storage in the inheritance
  // chain when writing upgradeable contracts.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
