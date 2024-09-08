// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ERC7656
 * @dev Modified registry based on ERC6551Registry
 * https://github.com/erc6551/reference/blob/main/src/ERC6551Registry.sol
 *
 * The ERC165 interfaceId is 0xc6bdc908
 * @notice Manages the creation of token linked services
 */
interface IERC7656Registry {
  /**
   * @notice The registry MUST emit the Created event upon successful contract creation.
   * @param contractAddress The address of the created contract
   * @param implementation The address of the implementation contract
   * @param salt The salt to use for the create2 operation
   * @param chainId The chain id of the chain where the contract is being created
   * @param tokenContract The address of the token contract
   * @param tokenId The id of the token
   */
  event Created(
    address contractAddress,
    address indexed implementation,
    bytes32 salt,
    uint256 chainId,
    address indexed tokenContract,
    uint256 indexed tokenId
  );

  /**
   * The registry MUST revert with CreationFailed error if the create2 operation fails.
   */
  error CreationFailed();

  /**
   * @notice Creates a token linked service for a non-fungible token.
   * If service has already been created, returns the service address without calling create2.
   * @param implementation The address of the implementation contract
   * @param salt The salt to use for the create2 operation
   * @param chainId The chain id of the chain where the service is being created
   * @param tokenContract The address of the token contract
   * @param tokenId The id of the token
   * Emits Created event.
   * @return service The address of the token linked service
   */
  function create(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId
  ) external returns (address service);

  /**
   * @notice Returns the computed token linked service address for a non-fungible token.
   * @param implementation The address of the implementation contract
   * @param salt The salt to use for the create2 operation
   * @param chainId The chain id of the chain where the service is being created
   * @param tokenContract The address of the token contract
   * @param tokenId The id of the token
   * @return service The address of the token linked service
   */
  function compute(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId
  ) external view returns (address service);
}
