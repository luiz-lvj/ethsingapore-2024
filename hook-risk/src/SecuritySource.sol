// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import { console } from "forge-std/Test.sol";

contract SecuritySource is Ownable {

    address[] public whitelistedERC20Tokens;
    address[] public priceFeedsWhitelistedERC20Tokens;
    address[] public volatilityFeedsWhitelistedERC20Tokens;

    mapping(address => bool) public isWhitelistedERC20Token;
    mapping(address => address) public tokenToPriceFeed;
    mapping(address => address) public tokenToVolatilityFeed;

    uint256 public numberWhitelistedERC20Tokens;

    constructor(address _initialOwner) Ownable(_initialOwner) {
        
    }

    function setWhitelistedERC20Tokens(address[] memory _tokens, address[] memory _priceFeeds, address[] memory _volFeeds) public onlyOwner {
        whitelistedERC20Tokens = _tokens;
        priceFeedsWhitelistedERC20Tokens = _priceFeeds;
        volatilityFeedsWhitelistedERC20Tokens = _volFeeds;

        numberWhitelistedERC20Tokens = _tokens.length;

        for(uint256 i = 0; i < _tokens.length; i++) {
            isWhitelistedERC20Token[_tokens[i]] = true;
            tokenToPriceFeed[_tokens[i]] = _priceFeeds[i];
            tokenToVolatilityFeed[_tokens[i]] = _volFeeds[i];
        }
    }
}

