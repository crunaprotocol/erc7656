// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC7656BytecodeLib, ERC7656Registry} from "../ERC7656Registry.sol";

contract ERC7656RegistryExt is ERC7656Registry {
  function getBytecode(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes12 mode,
    address linkedContract,
    uint256 linkedId
  ) external pure returns (bytes memory) {
    return ERC7656BytecodeLib.getCreationCode(implementation, salt, chainId, mode, linkedContract, linkedId);
  }
}
