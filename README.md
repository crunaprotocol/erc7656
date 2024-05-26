# ERC-7656

This is a reference implementation for the ERC-7656 standard taken from the [Cruna Protocol](https://github.com/crunaprotocol/cruna-protocol) implementation, which also has full coverage of the smart contracts.

The following bytecode:

```
0x608060405234801561001057600080fd5b506102ac806100206000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c806301ffc9a714610046578063188db64e1461007f578063de307f46146100aa575b600080fd5b61006a6100543660046101db565b6001600160e01b0319166318d7b92160e31b1490565b60405190151581526020015b60405180910390f35b61009261008d366004610228565b6100bd565b6040516001600160a01b039091168152602001610076565b6100926100b8366004610228565b610121565b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b60015284601552605560002060601b60601c60005260206000f35b600060806024608c376e5af43d82803e903d91602b57fd5bf3606c5285605d52733d60ad80600a3d3981f3363d3d373d3d3d363d7360495260ff60005360b76055206035523060601b600152846015526055600020803b6101cb578560b760556000f5806101975763d786d3936000526004601cfd5b80606c52508284887fc6989e4f290074742210cbd6491de7ded9cfe2cd247932a53d31005007a6341a6060606ca46020606cf35b8060601b60601c60005260206000f35b6000602082840312156101ed57600080fd5b81356001600160e01b03198116811461020557600080fd5b9392505050565b80356001600160a01b038116811461022357600080fd5b919050565b600080600080600060a0868803121561024057600080fd5b6102498661020c565b945060208601359350604086013592506102656060870161020c565b94979396509194608001359291505056fea2646970667358221220a1eb08bd0d109d374fd4407e83d3b08f6b15af09e7c6a54b68d446696c062ad764736f6c63430008160033
```

has been deployed to the following address:

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
```

The code has been verified on most mainnets. 

Look at `contracts/bytecode.json` for the details.

## Usage

Install it as a dependency
```
npm i erc7656 @openzeppelin/contracts erc6551
```
[README.md](README.md)
Make your nft able to deploy plugins

```solidity
// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc7656/utils/ERC7656Deployer.sol";

contract MyExpandableToken is ERC721, Ownable, ERC7656Deployer {
  
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
    // passing address(0) as the manager address, since the token is the manager
    _deploy(implementation, salt, address(this), tokenId, address(0));
    
  }
  
}
```

For more elaborate example, take a look at the [Cruna Protocol](https://github.com/crunaprotocol/cruna-protocol).

Notice that the plugin can be deployed by anyone, not only by the owner. Deploying it from the token itself, however, allows for more controls; for example, if executing an initializing function allowed only by the token owner.

## License

MIT

Copyright (C) 2023+ Cruna
[README.md](README.md)