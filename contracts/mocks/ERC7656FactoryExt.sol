// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC7656Factory} from "../ERC7656Factory.sol";
import {ERC7656BytecodeLib} from "../lib/ERC7656BytecodeLib.sol";

contract ERC7656FactoryExt is ERC7656Factory {
  function getCreationBytecode(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes12 mode,
    address linkedContract,
    uint256 linkedId
  ) external pure returns (bytes memory) {
    return ERC7656BytecodeLib.getCreationCode(implementation, salt, chainId, mode, linkedContract, linkedId);
  }

  function getComputedAddress(
    bytes32 salt,
    bytes memory bytecode,
    address deployer
  ) external view returns (address) {
    return ERC7656BytecodeLib.computeAddress(salt, keccak256(bytecode), deployer);
  }
}
