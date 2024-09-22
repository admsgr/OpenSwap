// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract FatalTravelQuest is ERC1155, Ownable {
  uint256[] public supplies = [50, 50, 50, 50, 50, 50, 150];
  uint256[] public minted = [0, 0, 0, 0, 0, 0, 0];
  mapping(uint256 => mapping(address => bool)) public member;
  mapping(address => bool) public callbackProxy;

  constructor() ERC1155('ipfs://QmeN1bj7QC3LFLU9cziaNxJQrem6pfVNWkgPp8DBpE4PKa/{id}.json') {}

  modifier onlyCallbackProxy() {
    require(callbackProxy[msg.sender], 'Only Proxy');
    _;
  }

  // to Put NFT to Opensea
  function uri(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId <= supplies.length - 1, 'NFT does not exist');
    return string(abi.encodePacked('ipfs://QmeN1bj7QC3LFLU9cziaNxJQrem6pfVNWkgPp8DBpE4PKa/', Strings.toString(_tokenId), '.json'));
  }

  function mint(uint256 _tokenId) public {
    require(!member[_tokenId][msg.sender], 'You have already claimed this NFT.');
    require(_tokenId <= supplies.length - 1, 'NFT does not exist');
    uint256 index = _tokenId;

    require(minted[index] + 1 <= supplies[index], 'All the NFT have been minted');
    _mint(msg.sender, _tokenId, 1, '');
    // "" is data which is set empty
    minted[index] += 1;
    member[_tokenId][msg.sender] = true;
  }

  function totalNftMinted(uint256 _tokenId) public view returns (uint256) {
    return minted[_tokenId];
  }
}
