// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {IERC7656Registry} from "../IERC7656Registry.sol";

/**
 * @title ERC7656Deployer
 * @notice This contract manages deploy-related functions
 */
abstract contract ERC7656Deployer {
  /**
   * @notice This function deploys a token-linked contract (manager or plugin)
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param erc7656Registry The address of the ERC7656Registry. If not set, the canonical registry deployed by Cruna Protocol will be used
   */
  function _isDeployed(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    address erc7656Registry
  ) internal view virtual returns (bool) {
    if (erc7656Registry == address(0)) {
      // canonical registry deployed by Cruna Protocol
      erc7656Registry = 0x7656CCCC1d93430f4E43A7ea0981C01469c9D6A2;
    }
    address _addr = _addressOfDeployed(implementation, salt, tokenAddress, tokenId, erc7656Registry);
    uint32 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(_addr)
    }
    return (size != 0);
  }

  /**
   * @notice Internal function to return the address of a token linked contract
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param erc7656Registry The address of the ERC7656Registry. If not set, the canonical registry deployed by Cruna Protocol will be used
   */
  function _addressOf(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    address erc7656Registry
  ) internal view virtual returns (address) {
    if (erc7656Registry == address(0)) {
      // canonical registry deployed by Cruna Protocol
      erc7656Registry = 0x7656CCCC1d93430f4E43A7ea0981C01469c9D6A2;
    }
    return ERC6551AccountLib.computeAddress(erc7656Registry, implementation, salt, block.chainid, tokenAddress, tokenId);
  }

  /**
   * @notice This function deploys a token-linked contract (manager or plugin)
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param erc7656Registry The address of the ERC7656Registry. If not set, the canonical registry deployed by Cruna Protocol will be used
   */
  function _deploy(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    address erc7656Registry
  ) internal virtual returns (address) {
    if (erc7656Registry == address(0)) {
      // canonical registry deployed by Cruna Protocol
      erc7656Registry = 0x7656CCCC1d93430f4E43A7ea0981C01469c9D6A2;
    }
    return IERC7656Registry(erc7656Registry).create(implementation, salt, block.chainid, tokenAddress, tokenId);
  }
}
