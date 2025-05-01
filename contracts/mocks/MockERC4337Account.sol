// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title MockERC4337Account
 * @notice A simplified mock of an ERC-4337 account for testing purposes
 */
contract MockERC4337Account is IERC721Receiver {
    event AccountTransferred(address indexed previousOwner, address indexed newOwner);
    event EntryPointUpdated(address indexed previousEntryPoint, address indexed newEntryPoint);

    address public owner;
    address public entryPoint;
    bool public isInitialized;

    error AlreadyInitialized();
    error NotEntryPoint();
    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Initialize the account with an entry point
     * @param _entryPoint The address of the entry point contract
     */
    function initialize(address _entryPoint) external {
        if (isInitialized) revert AlreadyInitialized();
        entryPoint = _entryPoint;
        isInitialized = true;
    }

    /**
     * @notice Update the entry point (only callable by the account itself)
     * @param newEntryPoint The new entry point address
     */
    function updateEntryPoint(address newEntryPoint) external {
        if (msg.sender != address(this)) revert NotOwner();
        address oldEntryPoint = entryPoint;
        entryPoint = newEntryPoint;
        emit EntryPointUpdated(oldEntryPoint, newEntryPoint);
    }

    /**
     * @notice Transfer account ownership (only callable by the account itself or the entry point)
     * @param newOwner The new owner address
     */
    function transferOwnership(address newOwner) public {
        if (msg.sender != address(this) && msg.sender != entryPoint) revert NotOwner();
        address oldOwner = owner;
        owner = newOwner;
        emit AccountTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Execute a transaction (only callable by the account itself or the entry point)
     * @param target The target address to execute the transaction
     * @param value The amount of ETH to send
     * @param data The calldata to send
     */
    function execute(address target, uint256 value, bytes calldata data) external returns (bytes memory) {
        require(msg.sender == owner || msg.sender == entryPoint, "Not authorized");
        (bool success, bytes memory result) = target.call{value: value}(data);
        require(success, "Execution failed");
        return result;
    }

    /**
     * @notice Validate a user operation (only callable by the entry point)
     * @dev This is a mock implementation that always returns success
     */
    function validateUserOp(
        bytes calldata /* userOp */,
        bytes32 /* userOpHash */,
        uint256 /* missingAccountFunds */
    ) external view returns (uint256) {
        if (msg.sender != entryPoint) revert NotEntryPoint();
        // In a real account, this would validate signatures, etc.
        // For our mock, we'll just return 0 to indicate success
        return 0;
    }

    /**
     * @notice Implementation of IERC721Receiver
     * @dev This is a mock implementation that always accepts NFTs
     */
    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Allow the account to receive ETH
    receive() external payable {}
} 