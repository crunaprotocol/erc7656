// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

//import "hardhat/console.sol";

contract SomeNiceNFT is ERC721, Ownable {
  constructor(address initialOwner) ERC721("SomeNiceNFT", "SNNFT") Ownable(initialOwner) {}

  function safeMint(address to, uint256 tokenId) public onlyOwner {
    _safeMint(to, tokenId);
  }
}
