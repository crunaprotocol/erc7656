// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IERC6982} from "./erc/IERC6982.sol";
import {ERC7656Deployer} from "../utils/ERC7656Deployer.sol";

//import "hardhat/console.sol";

/**
 * @title CrunaProtectedNFT
 * @notice This contracts is a base for NFTs with protected transfers. It must be extended implementing
 * the _canManage function to define who can alter the contract. Two versions are provided in this repo,CrunaProtectedNFTTimeControlled.sol and CrunaProtectedNFTOwnable.sol. The first is the recommended one, since it allows a governance aligned with best practices. The second is simpler, and can be used in less critical scenarios. If none of them fits your needs, you can implement your own policy.
 */
abstract contract ExpandableNFT is IERC6982, ERC7656Deployer, ERC721 {
  using Strings for uint256;
  using Address for address;

  /**
   * @notice Set a convenient variable to refer to the contract itself
   */
  address internal immutable _SELF = address(this);

  modifier onlyTokenOwner(uint256 tokenId) {
    if (ownerOf(tokenId) != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  error NotTransferable();
  error NotTheTokenOwner();

  constructor(string memory name_, string memory symbol_) payable ERC721(name_, symbol_) {
    emit DefaultLocked(false);
  }

  /// @dev see {ERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == type(IERC6982).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @notice Returns the current default lock status for tokens.
   * The returned value MUST reflect the status indicated by the most recent `DefaultLocked` event.
   */
  function defaultLocked() external pure virtual override returns (bool) {
    // override it!
    return false;
  }

  /**
   * @notice Returns the lock status of a specific token.
   * If no `Locked` event has been emitted for the token, it MUST return the current default lock status.
   * The function MUST revert if the token does not exist.
   */
  function locked(uint256) external view virtual override returns (bool) {
    // override it!
    return false;
  }

  /**
   * @notice Deploys an unmanaged service
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   */
  function plug(address implementation, bytes32 salt, uint256 tokenId) external virtual onlyTokenOwner(tokenId) {
    _deploy(implementation, salt, _SELF, tokenId, address(0));
  }

  /**
   * @notice Returns if a plugin is deployed
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   */
  function isDeployed(address implementation, bytes32 salt, uint256 tokenId) external view virtual returns (bool) {
    return _isDeployed(implementation, salt, _SELF, tokenId, address(0));
  }

  /**
   * @notice Returns the address of a deployed manager or plugin
   * @param implementation The address of the implementation
   * @param salt The salt
   * @param tokenId The tokenId
   * @return The address of the deployed manager or plugin
   */
  function addressOf(address implementation, bytes32 salt, uint256 tokenId) external view virtual returns (address) {
    return _addressOf(implementation, salt, _SELF, tokenId, address(0));
  }
}
