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
   * @param registry The address of the ERC7656Registry. If not set, the canonical registry deployed by Cruna Protocol will be used
   */
  function _isDeployed(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    address registry
  ) internal view virtual returns (bool) {
    address _addr = _addressOf(implementation, salt, tokenAddress, tokenId, _canonicalERC7656Registry(registry));
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
   * @param registry The address of the ERC7656Registry. If not set, the canonical registry deployed by Cruna Protocol will be used
   */
  function _addressOf(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    address registry
  ) internal view virtual returns (address) {
    return
      ERC6551AccountLib.computeAddress(
        _canonicalERC7656Registry(registry),
        implementation,
        salt,
        block.chainid,
        tokenAddress,
        tokenId
      );
  }

  /**
   * @notice This function deploys a token-linked contract (manager or plugin)
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param registry The address of the ERC7656Registry. If not set, the canonical registry deployed by Cruna Protocol will be used
   */
  function _deploy(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    address registry
  ) internal virtual returns (address) {
    return
      IERC7656Registry(_canonicalERC7656Registry(registry)).create(implementation, salt, block.chainid, tokenAddress, tokenId);
  }

  function _canonicalERC7656Registry(address registry) internal pure returns (address) {
    if (registry != address(0)) {
      return registry;
    }
    return 0x7656CCCC1d93430f4E43A7ea0981C01469c9D6A2;
  }
}
