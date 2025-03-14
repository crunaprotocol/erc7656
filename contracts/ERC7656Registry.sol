// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC7656Registry} from "./interfaces/IERC7656Registry.sol";

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC7656Registry is IERC165, IERC7656Registry {
  function create(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes1 mode,
    address linkedContract,
    uint256 id
  ) external returns (address service) {
    bytes memory erc1167Header = hex"3d602d80600a3d3981f3363d3d373d3d3d363d73";
    bytes memory erc1167Footer = hex"5af43d82803e903d91602b57fd5bf3";

    bytes memory creationCode;

    // Determine bytecode based on mode
    if (mode == 0x00) {
      // Mode with ID
      assembly {
        // Calculate the required memory size
        let size := add(
          add(
            add(
              add(
                add(
                  add(
                    add(
                      mload(erc1167Header), // ERC-1167 Header size
                      20
                    ), // implementation address size
                    mload(erc1167Footer)
                  ), // ERC-1167 Footer size
                  32
                ), // salt size
                32
              ), // chainId size
              12
            ), // mode (1 byte) + reserved (11 bytes)
            20
          ), // linkedContract address size
          32
        ) // id size (only for mode 0x00)

        // Allocate memory for the creation code
        creationCode := mload(0x40)
        mstore(0x40, add(creationCode, add(size, 32))) // Update free memory pointer
        mstore(creationCode, size) // Store length

        // Copy ERC-1167 Header
        let destPtr := add(creationCode, 32)
        let srcPtr := add(erc1167Header, 32)
        let headerSize := mload(erc1167Header)
        for {
          let i := 0
        } lt(i, headerSize) {
          i := add(i, 32)
        } {
          mstore(add(destPtr, i), mload(add(srcPtr, i)))
        }
        destPtr := add(destPtr, headerSize)

        // Copy implementation address
        mstore(destPtr, and(implementation, 0xffffffffffffffffffffffffffffffffffffffff))
        destPtr := add(destPtr, 20)

        // Copy ERC-1167 Footer
        srcPtr := add(erc1167Footer, 32)
        let footerSize := mload(erc1167Footer)
        for {
          let i := 0
        } lt(i, footerSize) {
          i := add(i, 32)
        } {
          mstore(add(destPtr, i), mload(add(srcPtr, i)))
        }
        destPtr := add(destPtr, footerSize)

        // Copy salt
        mstore(destPtr, salt)
        destPtr := add(destPtr, 32)

        // Copy chainId
        mstore(destPtr, chainId)
        destPtr := add(destPtr, 32)

        // Copy mode and reserved bytes
        mstore8(destPtr, and(mode, 0xff))
        destPtr := add(destPtr, 1)

        // Zero out reserved bytes
        for {
          let i := 0
        } lt(i, 11) {
          i := add(i, 1)
        } {
          mstore8(add(destPtr, i), 0)
        }
        destPtr := add(destPtr, 11)

        // Copy linkedContract address
        mstore(destPtr, and(linkedContract, 0xffffffffffffffffffffffffffffffffffffffff))
        destPtr := add(destPtr, 20)

        // Copy id
        mstore(destPtr, id)
      }
    } else if (mode == 0x01) {
      // Mode without ID
      assembly {
        // Calculate the required memory size (without ID)
        let size := add(
          add(
            add(
              add(
                add(
                  add(
                    mload(erc1167Header), // ERC-1167 Header size
                    20
                  ), // implementation address size
                  mload(erc1167Footer)
                ), // ERC-1167 Footer size
                32
              ), // salt size
              32
            ), // chainId size
            12
          ), // mode (1 byte) + reserved (11 bytes)
          20
        ) // linkedContract address size

        // Allocate memory for the creation code
        creationCode := mload(0x40)
        mstore(0x40, add(creationCode, add(size, 32))) // Update free memory pointer
        mstore(creationCode, size) // Store length

        // Copy ERC-1167 Header
        let destPtr := add(creationCode, 32)
        let srcPtr := add(erc1167Header, 32)
        let headerSize := mload(erc1167Header)
        for {
          let i := 0
        } lt(i, headerSize) {
          i := add(i, 32)
        } {
          mstore(add(destPtr, i), mload(add(srcPtr, i)))
        }
        destPtr := add(destPtr, headerSize)

        // Copy implementation address
        mstore(destPtr, and(implementation, 0xffffffffffffffffffffffffffffffffffffffff))
        destPtr := add(destPtr, 20)

        // Copy ERC-1167 Footer
        srcPtr := add(erc1167Footer, 32)
        let footerSize := mload(erc1167Footer)
        for {
          let i := 0
        } lt(i, footerSize) {
          i := add(i, 32)
        } {
          mstore(add(destPtr, i), mload(add(srcPtr, i)))
        }
        destPtr := add(destPtr, footerSize)

        // Copy salt
        mstore(destPtr, salt)
        destPtr := add(destPtr, 32)

        // Copy chainId
        mstore(destPtr, chainId)
        destPtr := add(destPtr, 32)

        // Copy mode and reserved bytes
        mstore8(destPtr, and(mode, 0xff))
        destPtr := add(destPtr, 1)

        // Zero out reserved bytes
        for {
          let i := 0
        } lt(i, 11) {
          i := add(i, 1)
        } {
          mstore8(add(destPtr, i), 0)
        }
        destPtr := add(destPtr, 11)

        // Copy linkedContract address
        mstore(destPtr, and(linkedContract, 0xffffffffffffffffffffffffffffffffffffffff))
      }
    } else {
      revert("Invalid mode");
    }

    // Deploy the contract using create2
    assembly {
      service := create2(0, add(creationCode, 32), mload(creationCode), salt)
      if iszero(extcodesize(service)) {
        revert(0, 0)
      }
    }
  }

  function compute(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes1 mode,
    address linkedContract,
    uint256 linkedId
  ) external view virtual override returns (address) {
    bytes memory bytecode = _getProxyBytecode(implementation, salt, chainId, linkedContract, mode, linkedId);
    return _calculateAddress(implementation, salt, bytecode);
  }

  function _getProxyBytecode(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    address linkedContract,
    bytes1 mode,
    uint256 linkedId
  ) internal pure returns (bytes memory) {
    bytes memory bytecode = new bytes(173); // 45 bytes for proxy + 128 bytes for data

    // ERC-1167 constructor + header
    bytecode[0] = 0x3d;
    bytecode[1] = 0x60;
    bytecode[2] = 0xad;
    bytecode[3] = 0x80;
    bytecode[4] = 0x60;
    bytecode[5] = 0x0a;
    bytecode[6] = 0x3d;
    bytecode[7] = 0x39;
    bytecode[8] = 0x81;
    bytecode[9] = 0xf3;

    // ERC-1167 implementation part
    bytecode[10] = 0x36;
    bytecode[11] = 0x3d;
    bytecode[12] = 0x3d;
    bytecode[13] = 0x37;
    bytecode[14] = 0x3d;
    bytecode[15] = 0x3d;
    bytecode[16] = 0x3d;
    bytecode[17] = 0x36;
    bytecode[18] = 0x3d;
    bytecode[19] = 0x73;

    // Implementation address
    assembly {
      mstore(add(bytecode, 20), implementation)
    }

    // Need to shift the implementation address to the right place
    for (uint i = 0; i < 20; i++) {
      bytecode[20 + i] = bytecode[32 + i];
    }

    // ERC-1167 footer
    bytecode[40] = 0x5a;
    bytecode[41] = 0xf4;
    bytecode[42] = 0x3d;
    bytecode[43] = 0x82;
    bytecode[44] = 0x80;

    // Here goes the appended data
    // Salt (32 bytes)
    assembly {
      mstore(add(bytecode, 45), salt)
    }

    // chainId (32 bytes)
    assembly {
      mstore(add(bytecode, 77), chainId)
    }

    // mode (1 byte) and 11 bytes reserved
    bytecode[109] = mode;

    // linkedContract (20 bytes)
    for (uint i = 0; i < 20; i++) {
      bytecode[121 + i] = bytes20(linkedContract)[i];
    }

    // linkedId (32 bytes)
    assembly {
      mstore(add(bytecode, 141), linkedId)
    }

    return bytecode;
  }

  function _calculateAddress(address implementation, bytes32 salt, bytes memory bytecode) internal view returns (address) {
    bytes32 bytecodeHash = keccak256(bytecode);
    bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash));
    return address(uint160(uint256(_data)));
  }

  /// @dev Returns true if interfaceId is IERC7656Registry's interfaceId
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IERC7656Registry).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}
