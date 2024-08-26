// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC165, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

import {IERC7656Service} from "../interfaces/IERC7656Service.sol";

//import "hardhat/console.sol";

/**
 * @title ERC7656Service.sol.sol
 * @notice Abstract contract to link a contract to an NFT
 */
abstract contract ERC7656Service is IERC7656Service, IERC165 {
  function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
    return interfaceId == type(IERC7656Service).interfaceId;
  }

  /**
   * @notice Returns the token linked to the contract
   */
  function token() public view virtual override returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  // @dev This empty reserved space is put in place to allow future versions
  // to add new variables without shifting down storage in the inheritance
  // chain when writing upgradeable contracts.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
