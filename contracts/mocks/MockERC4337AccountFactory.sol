// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@account-abstraction/contracts/interfaces/ISenderCreator.sol";
import "./MockERC4337Account.sol";

/**
 * @title MockERC4337AccountFactory
 * @notice Factory contract for deploying MockERC4337Account instances through proxies
 */
contract MockERC4337AccountFactory {
    MockERC4337Account public immutable accountImplementation;
    ISenderCreator public immutable senderCreator;
    IEntryPoint public immutable entryPoint;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new MockERC4337Account(_entryPoint);
        senderCreator = _entryPoint.senderCreator();
        entryPoint = _entryPoint;
    }

    receive() external payable {}

    /**
     * @notice Creates a new account instance
     * @param owner The owner of the account
     * @param salt A unique salt for deterministic deployment
     * @return ret The deployed account instance
     */
    function createAccount(address owner, uint256 salt) external returns (MockERC4337Account ret) {
        require(msg.sender == address(senderCreator), "only callable from SenderCreator");
        address addr = getAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return MockERC4337Account(payable(addr));
        }
        ret = MockERC4337Account(payable(new ERC1967Proxy{salt: bytes32(salt)}(
            address(accountImplementation),
            abi.encodeCall(MockERC4337Account.initialize, (owner))
        )));
    }

    /**
     * @notice Computes the deterministic address for an account before it is deployed
     * @param owner The owner of the account
     * @param salt A unique salt for deterministic deployment
     * @return The computed address
     */
    function getAddress(address owner, uint256 salt) public view returns (address) {
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(MockERC4337Account.initialize, (owner))
                )
            ))
        );
    }

    /**
     * @notice Creates an account directly, bypassing the SenderCreator check (for testing)
     * @param owner The owner of the account
     * @param salt A unique salt for deterministic deployment
     * @return ret The deployed account instance
     */
    function createAccountForTest(address owner, uint256 salt) external returns (MockERC4337Account ret) {
        address addr = getAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return MockERC4337Account(payable(addr));
        }
        ret = MockERC4337Account(payable(new ERC1967Proxy{salt: bytes32(salt)}(
            address(accountImplementation),
            abi.encodeCall(MockERC4337Account.initialize, (owner))
        )));
    }
} 