// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import { VaultHubChainFactory } from "../contracts/VaultHubChainFactory.sol";
import { MockERC20 } from "../contracts/mocks/MockERC20.sol";
import { MockChainlinkDataFeed } from "../contracts/mocks/MockChainlinkDataFeed.sol";
import { VaultHubChainAccount } from "../contracts/VaultHubChainAccount.sol";

import { MockChainlinkDataFeed } from "../contracts/mocks/MockChainlinkDataFeed.sol";

import { SecuritySource } from "../contracts/SecuritySource.sol";

contract DeployHubChainSepolia is Script {
    
    VaultHubChainFactory public factoryHubChain;

    SecuritySource public securitySourceHubChain;




    function setUp() public {}


    function securitySet() public {

    }

    function run() public {

        //uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        address owner = 0x000ef5F21dC574226A06C76AAE7060642A30eB74;

        
        MockERC20 token1 = new MockERC20("BTC", "BTC");
        MockERC20 token2 = new MockERC20("ETH", "ETH");
        MockERC20 token3 = new MockERC20("LINK", "LINK");
        MockERC20 currency = MockERC20(0x50914077B638196Eff4bCAB090b6d8e8f19b53eE);

        address priceFeedToken4 = address(new MockChainlinkDataFeed(100000000));
        address volFeedToken4 = address(new MockChainlinkDataFeed(0));

        address[] memory tokens = new address[](4);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(token3);
        tokens[3] = address(currency);

        address[] memory priceFeeds = new address[](4);
        priceFeeds[0] = address(new MockChainlinkDataFeed(6306055000000));
        priceFeeds[1] = address(new MockChainlinkDataFeed(100000000));
        priceFeeds[2] = address(new MockChainlinkDataFeed(50000000));
        priceFeeds[3] = priceFeedToken4;

        address[] memory volFeeds = new address[](4);
        volFeeds[0] = address(new MockChainlinkDataFeed(67415));
        volFeeds[1] = address(new MockChainlinkDataFeed(0));
        volFeeds[2] = address(new MockChainlinkDataFeed(70000));
        volFeeds[3] = volFeedToken4;

        address securitySourceSepolia = 0x68A4AC5F5942744BCbd51482F9b81e9FA3408139;
        

        securitySourceHubChain = SecuritySource(securitySourceSepolia);

        securitySourceHubChain.setWhitelistedERC20Tokens(tokens, priceFeeds, volFeeds);

        factoryHubChain = VaultHubChainFactory(0x22599F1d29F97F66ECdAAfD03dc8bE60ac45575D);

        factoryHubChain.setSecuritySourceHubchain(securitySourceSepolia);

        //create new vault
        uint256 vaultId = factoryHubChain.createVault();
        VaultHubChainAccount vault = VaultHubChainAccount(payable(factoryHubChain.vaultHubChainAccounts(vaultId)));

        currency.mint(owner, 100 ether);

        currency.approve(address(vault), 100 ether);
        vault.deposit(50 ether);

        token1.mint(address(vault), 1 ether);
        token2.mint(address(vault), 1 ether);
        token3.mint(address(vault), 1 ether);
        currency.mint(address(vault), 1 ether);

        vault.evaluateTotalValue();

        //vault.deposit(25 ether);

        vm.stopBroadcast();
        
    }
}