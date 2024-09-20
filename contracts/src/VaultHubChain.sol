// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract VaultHubChain is ERC721, Ownable {
    uint256 public tokenCounter;

    

    constructor(address _initialOwner) ERC721("VaultHubChain", "VHC") Ownable(_initialOwner)  {
        tokenCounter = 0;

    }
}