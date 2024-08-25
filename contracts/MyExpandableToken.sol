// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/ERC7656Deployer.sol";

contract MyExpandableToken is ERC721, Ownable, ERC7656Deployer {
  error NotTheTokenOwner();

  constructor(address initialOwner) ERC721("MyExpandableToken", "MET") Ownable(initialOwner) {}

  function safeMint(address to, uint256 tokenId) public onlyOwner {
    _safeMint(to, tokenId);
  }

  function deployContractsOwnedByTheTokenId(address implementation, bytes32 salt, uint256 tokenId) external payable virtual {
    if (_msgSender() != ownerOf(tokenId)) revert NotTheTokenOwner();
    // passing address(0) as the registry address because we use the canonical one
    _deploy(implementation, salt, address(this), tokenId, address(0));
  }
}
