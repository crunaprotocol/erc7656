// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

import {EIP5313} from "../interfaces/EIP5313.sol";
import {IERC7656ServiceExt} from "./IERC7656ServiceExt.sol";
import {IERC7656Service} from "../interfaces/IERC7656Service.sol";
import {ERC7656Service} from "../ERC7656Service.sol";

//import "hardhat/console.sol";

/**
 * @title ERC7656ServiceExt.sol.sol.sol
 * @notice Abstract contract to link a contract to an NFT
 */
abstract contract ERC7656ServiceExt is ERC7656Service, IERC7656ServiceExt, EIP5313 {
  function supportsInterface(bytes4 interfaceId) public pure virtual override(ERC7656Service) returns (bool) {
    return
      interfaceId == type(IERC7656ServiceExt).interfaceId ||
      interfaceId == type(EIP5313).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @notice Returns the token linked to the contract
   */
  function token() public view virtual override(ERC7656Service, IERC7656Service) returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  /**
   * @notice Returns the owner of the token
   */
  function owner() public view virtual override returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = ERC6551AccountLib.token();
    if (chainId != block.chainid) return address(0);
    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  /**
   * @notice Returns the salt used when creating the contract
   */
  function salt() public view virtual override returns (bytes32) {
    return ERC6551AccountLib.salt();
  }

  /**
   * @notice Returns the address of the token contract
   */
  function tokenAddress() public view virtual override returns (address) {
    (, address tokenContract_, ) = ERC6551AccountLib.token();
    return tokenContract_;
  }

  /**
   * @notice Returns the tokenId of the token
   */
  function tokenId() public view virtual override returns (uint256) {
    (, , uint256 tokenId_) = ERC6551AccountLib.token();
    return tokenId_;
  }

  /**
   * @notice Returns the implementation used when creating the contract
   */
  function implementation() public view virtual override returns (address) {
    return ERC6551AccountLib.implementation();
  }

  // @dev This empty reserved space is put in place to allow future versions
  // to add new variables without shifting down storage in the inheritance
  // chain when writing upgradeable contracts.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
