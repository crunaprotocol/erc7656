// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC7656ServiceLib} from "../lib/ERC7656ServiceLib.sol";

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
   * @notice Returns the salt used when creating the contract
   */
  function salt() external view virtual override returns (bytes32) {
    return _salt();
  }

  /**
   * @notice Returns the address of the token contract
   */
  function linkedContract() external view virtual override returns (address) {
    return _linkedContract();
  }

  /**
   * @notice Returns the linkedId of the token
   */
  function linkedId() external view virtual override returns (uint256) {
    return _linkedId();
  }

  function mode() external view virtual override returns (bytes12) {
    return _mode();
  }

  function chainId() external view virtual override returns (uint256) {
    return _chainId();
  }

  /**
   * @notice Returns the implementation used when creating the contract
   */
  function implementation() external view virtual override returns (address) {
    return _implementation();
  }

  function _salt() internal view virtual returns (bytes32) {
    return ERC7656ServiceLib.salt();
  }

  function _chainId() internal view virtual returns (uint256) {
    (uint256 chainId_, , , ) = _linkedData();
    return chainId_;
  }


  function _mode() internal view virtual returns (bytes12) {
    (, bytes12 mode_, , ) = _linkedData();
    return mode_;
  }

  function _linkedContract() internal view returns (address) {
    (, , address tokenContract_, ) = _linkedData();
    return tokenContract_;
  }

  function _linkedId() internal view returns (uint256) {
    (, , , uint256 linkedId_) = _linkedData();
    return linkedId_;
  }

  function _implementation() internal view returns (address) {
    return ERC7656ServiceLib.implementation();
  }

  // @dev This empty reserved space is put in place to allow future versions
  // to add new variables without shifting down storage in the inheritance
  // chain when writing upgradeable contracts.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
