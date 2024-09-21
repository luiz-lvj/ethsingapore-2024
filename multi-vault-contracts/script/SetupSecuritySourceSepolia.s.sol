// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import { VaultHubChainFactory } from "../contracts/VaultHubChainFactory.sol";
import { MockERC20 } from "../contracts/mocks/MockERC20.sol";
import { MockChainlinkDataFeed } from "../contracts/mocks/MockChainlinkDataFeed.sol";
import { VaultHubChainAccount } from "../contracts/VaultHubChainAccount.sol";

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
        MockERC20 currency = MockERC20(0x5B71e5EED1BFee7f85169eDDee6b48F1abd68431);

        address priceFeedToken4 = address(new MockChainlinkDataFeed(100000000));
        address volFeedToken4 = address(new MockChainlinkDataFeed(0));

        address[] memory tokens = new address[](4);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(token3);
        tokens[3] = address(currency);

        address[] memory priceFeeds = new address[](4);
        priceFeeds[0] = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;
        priceFeeds[1] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[2] = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
        priceFeeds[3] = priceFeedToken4;

        address[] memory volFeeds = new address[](4);
        volFeeds[0] = 0xabfe1e28F54Ac40776DfCf2dF0874D37254D5F59;
        volFeeds[1] = 0x8e604308BD61d975bc6aE7903747785Db7dE97e2;
        volFeeds[2] = 0xd599cEF88Bbd27F1392A544bD0F343ec8893124C;
        volFeeds[3] = volFeedToken4;

        address securitySourceSepolia = 0x5140dF8128A644c9517d18C58a00c8e8FB9677b5;
        

        securitySourceHubChain = SecuritySource(securitySourceSepolia);

        securitySourceHubChain.setWhitelistedERC20Tokens(tokens, priceFeeds, volFeeds);

        factoryHubChain = VaultHubChainFactory(0xc9A98C1697B7F46d2074bf8aFEE41F516cAbDCd0);

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