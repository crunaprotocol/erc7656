// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockEntryPoint
 * @notice A simplified mock of an ERC-4337 entry point for testing purposes
 */
contract MockEntryPoint {
    error NotAccount();

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
     * @param account The account to execute the operation for
     * @param dest The destination address
     * @param value The amount of ETH to send
     * @param data The calldata to send
     */
    function handleOps(
        address account,
        address dest,
        uint256 value,
        bytes calldata data
    ) external payable {
        if (!isAccount[account]) revert NotAccount();
        
        // Call the account's execute function
        (bool success, ) = account.call(
            abi.encodeWithSignature(
                "execute(address,uint256,bytes)",
                dest,
                value,
                data
            )
        );
        require(success, "Execution failed");
    }

    // Allow the entry point to receive ETH
    receive() external payable {}
} 