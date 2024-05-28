// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC7656Linked.sol.sol
 */
interface IERC7656Linked {
  /**
   * @notice Returns the token linked to the contract
   * @return chainId The chainId of the token
   * @return tokenContract The address of the token contract
   * @return tokenId The tokenId of the token
   */
  function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId);
}
