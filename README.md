# ERC-7656

This is a reference implementation for the ERC-7656 standard taken from the [Cruna Protocol](https://github.com/crunaprotocol/cruna-protocol) implementation, which also has full coverage of the smart contracts.

The following bytecode:

```
0x608060405234801561001057600080fd5b506102ac806100206000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c806301ffc9a714610046578063188db64e1461007f578063de307f46146100aa575b600080fd5b61006a6100543660046101db565b6001600160e01b0319166318d7b92160e31b1490565b60405190151581526020015b60405180910390f35b61009261008d366004610228565b6100bd565b6040516001600160a01b039091168152602001610076565b6100926100b8366004610228565b610121565b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b60015284601552605560002060601b60601c60005260206000f35b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b600152846015526055600020803b6101cb578560b760556000f5806101975763d786d3936000526004601cfd5b80606c52508284887fc6989e4f290074742210cbd6491de7ded9cfe2cd247932a53d31005007a6341a6060606ca46020606cf35b8060601b60601c60005260206000f35b6000602082840312156101ed57600080fd5b81356001600160e01b03198116811461020557600080fd5b9392505050565b80356001600160a01b038116811461022357600080fd5b919050565b600080600080600060a0868803121561024057600080fd5b6102498661020c565b945060208601359350604086013592506102656060870161020c565b94979396509194608001359291505056fea2646970667358221220a1eb08bd0d109d374fd4407e83d3b08f6b15af09e7c6a54b68d446696c062ad764736f6c63430008160033
```

has been deployed to erc7656.eth, i.e.:

```
0x7656f0fB4Ca6973cf99D910B36705a2dEDA97eA1
```

via Nick's Factory using the following salt:

```
0x765600000000000000000000000000000000000000000000000000000000cf7e
```

on the following mainnets:
```
Etherum
Polygon
BNB Chain
Base
```
and the following testnets:
```
Avalanche Fuji
Celo Alfajores
Base Sepolia
Arbitrum Sepolia
```

The code has been verified on most mainnets. 

Look at `contracts/bytecode.json` for the details.

To see if it has been deployed by others on other chains, look at
https://blockscan.com/address/0x7656f0fB4Ca6973cf99D910B36705a2dEDA97eA1

## Usage

Install it as a dependency
```
npm i erc7656 @openzeppelin/contracts
```
Make your nft able to deploy plugins

```solidity
// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC7656DeployLib} from "erc7656/utils/ERC7656DeployLib.sol";

contract MyExpandableToken is ERC721, Ownable {
  
  error NotTheTokenOwner();
  
  constructor(address initialOwner) 
    ERC721("MyExpandableToken", "MET") 
    Ownable(initialOwner) {
  }

  function safeMint(address to, uint256 tokenId) public onlyOwner {
    _safeMint(to, tokenId);
  }

  function deployContractsOwnedByTheTokenId(
    address implementation,
    bytes32 salt,
    uint256 tokenId
  ) external payable virtual override {
    if (_msgSender() != ownerOf(tokenId)) revert NotTheTokenOwner();
    // passing address(0) as the registry address because we use the canonical one
    ERC7656DeployLib.deploy(implementation, salt, address(this), tokenId, address(0));
    
  }
  
}
```

To make your plugin extend `exr7656/ERC7656Service.sol` or `erc7656/extensions/ERC7656ServiceExt`.

---

Notice that anyone can deploy a service owned by a specific token, usign whatever salt they prefer. To avoid troubles and security issues, any initial setup must be designed so that, despite who is the deployer, the result is what is expected to be. For example, if a service must get some information from the token, it should be the service the one that queries the token, not the other way around. In other words, passing any parameter to the service during the deploying opens to the possibility of a malicious deployer to pass a different set of data causing the service to behave unexpectedly. 

## License

MIT

Copyright (C) 2023+ Cruna
