// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Modified from https://github.com/erc6551/reference/tree/main/src/lib

library ERC6551AccountLib {
  function implementation(address service) internal view returns (address _implementation) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // copy proxy implementation (0x14 bytes)
      extcodecopy(service, 0xC, 0xA, 0x14)
      _implementation := mload(0x00)
    }
  }

  function implementation() internal view returns (address _implementation) {
    return implementation(address(this));
  }

  function linkedContract(address service) internal view returns (uint256, address, uint256) {
    bytes memory encodedData = new bytes(0x60);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // copy 0x60 bytes from end of context
      extcodecopy(service, add(encodedData, 0x20), 0x4d, 0x60)
    }

    // if mode is 0x01, the id is not part of the bytecode
    // and this function will return 0 for the id
    return abi.decode(encodedData, (uint256, address, uint256));
  }

  function linkedContract() internal view returns (uint256, address, uint256) {
    return linkedContract(address(this));
  }

  function salt(address service) internal view returns (bytes32) {
    bytes memory encodedData = new bytes(0x20);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // copy 0x20 bytes from beginning of context
      extcodecopy(service, add(encodedData, 0x20), 0x2d, 0x20)
    }

    return abi.decode(encodedData, (bytes32));
  }

  function salt() internal view returns (bytes32) {
    return salt(address(this));
  }

  function context(address service) internal view returns (bytes32, uint256, address, uint256) {
    bytes memory encodedData = new bytes(0x80);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // copy full context (0x80 bytes)
      extcodecopy(service, add(encodedData, 0x20), 0x2D, 0x80)
    }

    return abi.decode(encodedData, (bytes32, uint256, address, uint256));
  }

  function context() internal view returns (bytes32, uint256, address, uint256) {
    return context(address(this));
  }
}
