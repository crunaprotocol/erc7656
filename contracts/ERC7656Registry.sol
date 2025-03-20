// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC7656Registry} from "./interfaces/IERC7656Registry.sol";
import {ERC7656BytecodeLib} from "./lib/ERC7656BytecodeLib.sol";

contract ERC7656Registry is IERC165, IERC7656Registry {
  /**
   * @dev Creates a proxy contract using the provided parameters
   * If the proxy already exists, returns its address without attempting creation
   */
  function create(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes12 mode,
    address linkedContract,
    uint256 linkedId
  ) external returns (address) {
    bytes memory bytecode = ERC7656BytecodeLib.getCreationCode(implementation, salt, chainId, mode, linkedContract, linkedId);
    address computedAddress = ERC7656BytecodeLib.computeAddress(salt, keccak256(bytecode), address(this));
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(computedAddress)
    }
    if (size == 0) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        // If the service has not yet been deployed
        let deployed := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

        // Revert if the deployment fails
        if iszero(deployed) {
          mstore(0x00, 0xd786d393) // `CreationFailed()`
          revert(0x1c, 0x04)
        }
        //        mstore(0x6c, deployed)
        //      // Return the service address
        //        return (0x6c, 0x20)
      }
      emit Created(computedAddress, implementation, salt, chainId, mode, linkedContract, linkedId);
    }
    return computedAddress;
  }

  /**
   * @dev Computes the address where the proxy will be deployed
   */
  function compute(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes12 mode,
    address linkedContract,
    uint256 linkedId
  ) external view returns (address) {
    bytes memory bytecode = ERC7656BytecodeLib.getCreationCode(implementation, salt, chainId, mode, linkedContract, linkedId);
    return ERC7656BytecodeLib.computeAddress(salt, keccak256(bytecode), address(this));
  }

  /// @dev Returns true if interfaceId is IERC7656Registry's interfaceId
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IERC7656Registry).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}
