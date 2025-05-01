// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockEntryPoint
 * @notice A simplified mock of an ERC-4337 entry point for testing purposes
 */
contract MockEntryPoint {
  error NotAccount();
  error OperationFailed();
  error NotRegistered();

  struct UserOperation {
    address sender;
    uint256 value;
    bytes callData;
  }

  mapping(address => bool) public isAccount;

  /**
   * @notice Simulates an account being registered with the entry point
   * @param account The account address to register
   */
  function registerAccount(address account) external {
    isAccount[account] = true;
  }

  /**
   * @notice Simulates a user operation being handled by the entry point
   * @param ops The array of UserOperations to handle
   */
  function handleOps(UserOperation[] calldata ops, address payable /* beneficiary */) external {
    for (uint256 i = 0; i < ops.length; i++) {
      UserOperation calldata op = ops[i];
      // Check if the sender is registered
      if (!isAccount[op.sender]) revert NotRegistered();
      // In a real implementation, we would validate the operation
      // For this mock, we just execute the call
      (bool success, ) = op.sender.call{value: op.value}(op.callData);
      if (!success) revert OperationFailed();
    }
  }

  // Allow the entry point to receive ETH
  receive() external payable {}
}
