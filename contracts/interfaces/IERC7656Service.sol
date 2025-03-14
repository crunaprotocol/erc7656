// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC7656Service.sol.sol.sol
 *   InterfaceId 0xfc0c546a
 */
interface IERC7656Service {
  /**
   * @notice Returns the token linked to the contract
   * @return chainId The chainId of the token
   * @return tokenContract The address of the token contract
   * @return linkedId The linkedId of the token
   */
  function linkedContract() external view returns (uint256 chainId, address tokenContract, uint256 linkedId);
}
