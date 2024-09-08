// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {ERC6551AccountLib} from "../lib/ERC6551AccountLib.sol";
import {IERC7656Registry} from "../interfaces/IERC7656Registry.sol";

/**
 * @title ERC7656Deployer
 * @notice This contract manages deploy-related functions
 */
library ERC7656DeployLib {
  /**
   * @notice It deploys a token-linked contract (manager or plugin)
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param registry The address of the ERC7656Registry. If not set, the canonical registry deployed by Cruna Protocol will be used
   */
  function isDeployed(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    address registry
  ) internal view returns (bool) {
    address _addr = addressOf(implementation, salt, tokenAddress, tokenId, canonicalERC7656Registry(registry));
    uint32 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(_addr)
    }
    return (size != 0);
  }

  /**
   * @notice Returns the address of a token linked contract
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @param registry The address of the ERC7656Registry. If not set, the canonical registry deployed by Cruna Protocol will be used
   */
  function addressOf(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    address registry
  ) internal view returns (address) {
    return
      ERC6551AccountLib.computeAddress(
        canonicalERC7656Registry(registry),
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
   * @param registry The address of the ERC7656Registry. If set to address(0), the canonical registry deployed by Cruna Protocol will be used
   */
  function deploy(
    address implementation,
    bytes32 salt,
    address tokenAddress,
    uint256 tokenId,
    address registry
  ) internal returns (address) {
    return
      IERC7656Registry(canonicalERC7656Registry(registry)).create(implementation, salt, block.chainid, tokenAddress, tokenId);
  }

  function canonicalERC7656Registry(address registry) internal pure returns (address) {
    if (registry != address(0)) {
      return registry;
    }
    return 0x7656f0fB4Ca6973cf99D910B36705a2dEDA97eA1;
  }
}
