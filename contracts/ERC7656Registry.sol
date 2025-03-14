// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC7656Registry} from "./interfaces/IERC7656Registry.sol";

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ERC7656Registry is IERC165, IERC7656Registry {
  // Constants at contract level
  bytes private constant ERC1167_HEADER = hex"3d602d80600a3d3981f3363d3d373d3d3d363d73";
  bytes private constant ERC1167_FOOTER = hex"5af43d82803e903d91602b57fd5bf3";

  /**
   * @dev Creates a proxy contract using the provided parameters
   * If the proxy already exists, returns its address without attempting creation
   */
  function create(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes1 mode,
    address linkedContract,
    uint256 id
  ) external returns (address service) {
    // Generate the initialization code
    bytes memory initCode = _generateInitCode(implementation, salt, chainId, mode, linkedContract, id);

    // Calculate the expected address
    address expectedAddress = _computeAddress(initCode, salt);

    // Check if contract already exists at the expected address
    uint256 codeSize;
    assembly {
      codeSize := extcodesize(expectedAddress)
    }

    // If the contract already exists, return its address without emitting an event
    if (codeSize > 0) {
      return expectedAddress;
    }

    // Deploy the contract using create2
    assembly {
      service := create2(0, add(initCode, 32), mload(initCode), salt)
      // Check if deployment was successful
      if iszero(extcodesize(service)) {
        // Deployment failed
        service := 0
      }
    }

    // Check if deployment was successful
    if (service == address(0)) {
      revert CreationFailed();
    }

    // Explicitly emit the Created event
    emit Created(service, implementation, salt, chainId, mode, linkedContract, id);

    return service;
  }

  /**
   * @dev Computes the address where the proxy will be deployed
   */
  function compute(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes1 mode,
    address linkedContract,
    uint256 linkedId
  ) external view returns (address) {
    // Generate the initialization code (same as in create)
    bytes memory initCode = _generateInitCode(implementation, salt, chainId, mode, linkedContract, linkedId);

    // Compute the address
    return _computeAddress(initCode, salt);
  }

  /**
   * @dev Internal function to compute the address using CREATE2 formula
   */
  function _computeAddress(bytes memory initCode, bytes32 salt) internal view returns (address) {
    bytes32 initCodeHash = keccak256(initCode);
    bytes32 rawAddress = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCodeHash));

    return address(uint160(uint256(rawAddress)));
  }

  /**
   * @dev Generates the initialization code for the proxy
   */
  function _generateInitCode(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    bytes1 mode,
    address linkedContract,
    uint256 linkedId
  ) internal pure returns (bytes memory) {
    // Get the bytecode constants
    bytes memory header = ERC1167_HEADER;
    bytes memory footer = ERC1167_FOOTER;

    // Calculate sizes
    uint256 headerSize = header.length;
    uint256 footerSize = footer.length;

    // Determine total size based on mode
    uint256 totalSize;
    if (mode == 0x00) {
      totalSize = headerSize + 20 + footerSize + 32 + 32 + 12 + 20 + 32; // With ID
    } else if (mode == 0x01) {
      totalSize = headerSize + 20 + footerSize + 32 + 32 + 12 + 20; // Without ID
    } else {
      revert("Invalid mode");
    }

    // Allocate memory for the creation code
    bytes memory initCode = new bytes(totalSize);

    // Copy the header
    uint256 destOffset = 0;
    for (uint256 i = 0; i < headerSize; i++) {
      initCode[destOffset++] = header[i];
    }

    // Copy implementation address
    bytes20 implBytes = bytes20(implementation);
    for (uint256 i = 0; i < 20; i++) {
      initCode[destOffset++] = implBytes[i];
    }

    // Copy the footer
    for (uint256 i = 0; i < footerSize; i++) {
      initCode[destOffset++] = footer[i];
    }

    // Copy salt (bytes32)
    for (uint256 i = 0; i < 32; i++) {
      initCode[destOffset++] = salt[i];
    }

    // Copy chainId (uint256 as bytes32)
    bytes32 chainIdBytes = bytes32(chainId);
    for (uint256 i = 0; i < 32; i++) {
      initCode[destOffset++] = chainIdBytes[i];
    }

    // Copy mode (bytes1)
    initCode[destOffset++] = mode;

    // Zero out reserved bytes (11 bytes)
    for (uint256 i = 0; i < 11; i++) {
      initCode[destOffset++] = 0;
    }

    // Copy linkedContract address (address as bytes20)
    bytes20 linkedBytes = bytes20(linkedContract);
    for (uint256 i = 0; i < 20; i++) {
      initCode[destOffset++] = linkedBytes[i];
    }

    // Copy linkedId if mode is 0x00 (with ID)
    if (mode == 0x00) {
      bytes32 linkedIdBytes = bytes32(linkedId);
      for (uint256 i = 0; i < 32; i++) {
        initCode[destOffset++] = linkedIdBytes[i];
      }
    }

    return initCode;
  }

  /// @dev Returns true if interfaceId is IERC7656Registry's interfaceId
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IERC7656Registry).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}
