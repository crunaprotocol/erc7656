// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {SimplifiedERC6551AccountLib} from "../lib/SimplifiedERC6551AccountLib.sol";

import {EIP5313} from "../interfaces/EIP5313.sol";
import {IERC7656ServiceExt} from "./IERC7656ServiceExt.sol";
import {ERC7656Service} from "../ERC7656Service.sol";

//import "hardhat/console.sol";

/**
 * @title ERC7656ServiceExt.sol.sol.sol
 * @notice Abstract contract to link a contract to an NFT
 */
abstract contract ERC7656ServiceExt is ERC7656Service, IERC7656ServiceExt, EIP5313 {
  /**
   * @notice Returns the owner of the token
   */
  function owner() public view virtual override returns (address) {
    return _owner();
  }

  /**
   * @notice Returns the salt used when creating the contract
   */
  function salt() public view virtual override returns (bytes32) {
    return SimplifiedERC6551AccountLib.salt();
  }

  /**
   * @notice Returns the address of the token contract
   */
  function tokenAddress() public view virtual override returns (address) {
    return _tokenAddress();
  }

  /**
   * @notice Returns the tokenId of the token
   */
  function tokenId() public view virtual override returns (uint256) {
    return _tokenId();
  }

  /**
   * @notice Returns the implementation used when creating the contract
   */
  function implementation() public view virtual override returns (address) {
    return _implementation();
  }

  /**
   * Private functions
   */

  function _owner() internal view returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = SimplifiedERC6551AccountLib.token();
    if (chainId != block.chainid) return address(0);
    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  function _tokenAddress() internal view returns (address) {
    (, address tokenContract_, ) = SimplifiedERC6551AccountLib.token();
    return tokenContract_;
  }

  function _tokenId() internal view returns (uint256) {
    (, , uint256 tokenId_) = SimplifiedERC6551AccountLib.token();
    return tokenId_;
  }

  function _implementation() internal view returns (address) {
    return SimplifiedERC6551AccountLib.implementation();
  }

  function version() external pure virtual returns (uint256) {
    return _version();
  }

  function _version() internal pure virtual returns (uint256) {
    return 1_000_000;
  }

  // @dev This empty reserved space is put in place to allow future versions
  // to add new variables without shifting down storage in the inheritance
  // chain when writing upgradeable contracts.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
