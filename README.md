# ERC-7656

This is a reference implementation for the ERC-7656 standard taken from the [Cruna Protocol](https://github.com/crunaprotocol/cruna-protocol) implementation, which also has full coverage of the smart contracts.

A canonical version has been deployed at the address 

0x7656f0fB4Ca6973cf99D910B36705a2dEDA97eA1 

using Nick's Factory with the following salt:

0x765600000000000000000000000000000000000000000000000000000000cf7e

on mainnets on Etherum, Polygon, BNB Chain, Base and on testnets on Avalanche Fuji, Celo Alfajores and Base Sepolia. The code on most mainnets has been verified.   

## Usage

Install it as a dependency
```
npm i erc7656 @openzeppelin/contracts erc6551
```

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