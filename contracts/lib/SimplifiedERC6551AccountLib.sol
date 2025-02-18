// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Taken from https://github.com/erc6551/reference/tree/main/src/lib
// to avoid future possible incompatibilities
// Simplified to remove unnecessary functions

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

library SimplifiedERC6551AccountLib {
  function implementation(address account) internal view returns (address _implementation) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // copy proxy implementation (0x14 bytes)
      extcodecopy(account, 0xC, 0xA, 0x14)
      _implementation := mload(0x00)
    }
  }

  function implementation() internal view returns (address _implementation) {
    return implementation(address(this));
  }

  function token(address account) internal view returns (uint256, address, uint256) {
    bytes memory encodedData = new bytes(0x60);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // copy 0x60 bytes from end of context
      extcodecopy(account, add(encodedData, 0x20), 0x4d, 0x60)
    }

    return abi.decode(encodedData, (uint256, address, uint256));
  }

  function token() internal view returns (uint256, address, uint256) {
    return token(address(this));
  }

  function salt(address account) internal view returns (bytes32) {
    bytes memory encodedData = new bytes(0x20);
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // copy 0x20 bytes from beginning of context
      extcodecopy(account, add(encodedData, 0x20), 0x2d, 0x20)
    }

    return abi.decode(encodedData, (bytes32));
  }

  function salt() internal view returns (bytes32) {
    return salt(address(this));
  }
}
