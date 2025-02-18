// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC7656ServiceExt, IERC7656ServiceExt} from "../../extensions/ERC7656ServiceExt.sol";

abstract contract BadgeCollectorService is ERC7656ServiceExt, IERC721Receiver, Context {
  event BadgeCollected(address indexed badgeAddress, uint256 indexed badgeTokenId, address from, uint256 timestamp);

  error InvalidValidity();
  error NotTheTokenOwner();

  modifier onlyTokenOwner() {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return (interfaceId == type(IERC7656ServiceExt).interfaceId ||
      interfaceId == type(IERC721Receiver).interfaceId ||
      interfaceId == type(IERC165).interfaceId);
  }

  function onERC721Received(address, address from, uint256 receivedTokenId, bytes memory) external virtual returns (bytes4) {
    emit BadgeCollected(_msgSender(), receivedTokenId, from, block.timestamp);
    return IERC721Receiver.onERC721Received.selector;
  }

  function transferBadge(address badgeAddress, uint256 badgeTokenId) external virtual onlyTokenOwner {
    // it will revert if the token is a soul-bound token or any locked token
    IERC721(badgeAddress).transferFrom(address(this), owner(), badgeTokenId);
  }
}
