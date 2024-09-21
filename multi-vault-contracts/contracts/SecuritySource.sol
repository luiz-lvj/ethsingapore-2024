// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import { console } from "forge-std/Test.sol";

contract SecuritySource is Ownable {

    address[] public whitelistedERC20Tokens;
    address[] public priceFeedsWhitelistedERC20Tokens;
    address[] public volatilityFeedsWhitelistedERC20Tokens;

    uint256 public numberWhitelistedERC20Tokens;

    constructor(address _initialOwner) Ownable(_initialOwner) {
        
    }

    function setWhitelistedERC20Tokens(address[] memory _tokens, address[] memory _priceFeeds, address[] memory _volFeeds) public onlyOwner {
        whitelistedERC20Tokens = _tokens;
        priceFeedsWhitelistedERC20Tokens = _priceFeeds;
        volatilityFeedsWhitelistedERC20Tokens = _volFeeds;

        numberWhitelistedERC20Tokens = _tokens.length;

        console.log("Whitelisted tokens: ", _tokens.length);
    }
}

