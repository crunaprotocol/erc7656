// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// This implementation is a variation of https://github.com/erc6551/reference/blob/main/src/lib/ERC6551BytecodeLib.sol
// Modified by: Francesco Sullo @sullof

library ERC7656BytecodeLib {
  /**
   * @dev Returns the creation code of a service linked to a contract
   * @return result The creation code of the linked service
   */
  function getCreationCode(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes12 mode,
    address linkedContract,
    uint256 linkedId
  ) internal pure returns (bytes memory result) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // data structure
      // 0x14: ERC-1167 Constructor + Header  (20 bytes)
      // 0x28: implementation                 (20 bytes)
      // 0x37: erc1167 footer                 (15 bytes)
      // 0x77: salt                           (32 bytes)
      // 0x57: chainId                        (32 bytes)
      // 0x97  mode                           (12 bytes)
      // 0xa9: linkedContract                 (20 bytes)
      // 0xb7: linkedId                       (32 bytes)
      result := mload(0x40) // Grab the free memory pointer
      mstore(add(result, 0x37), 0x5af43d82803e903d91602b57fd5bf3) // erc1167 footer
      mstore(add(result, 0x28), implementation)
      mstore(add(result, 0x14), 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73)
      mstore(add(result, 0x57), salt)
      mstore(add(result, 0x77), chainId) //
      mstore(add(result, 0x97), or(mode, linkedContract)) //
      mstore(add(result, 0xb7), linkedId)
      mstore(result, 0xb7) // Store the length
      mstore(0x40, add(result, 0xd7)) // Allocate the memory
    }
  }

  function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address result) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := mload(0x40) // Grab the free memory pointer
      mstore8(result, 0xff)
      mstore(add(result, 0x35), bytecodeHash)
      mstore(add(result, 0x01), shl(96, deployer))
      mstore(add(result, 0x15), salt)
      result := keccak256(result, 0x55)
    }
  }
}
