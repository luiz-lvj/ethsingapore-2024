// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { ERC6551Registry } from "../src/ERC6551Registry.sol";
import { VaultHubChainAccount } from "../src/VaultHubChainAccount.sol";
import { VaultHubChainFactory } from "../src/VaultHubChainFactory.sol";
import { SecuritySource } from "../src/SecuritySource.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";
import { MockChainlinkDataFeed } from "../src/mocks/MockChainlinkDataFeed.sol";

//import { TestHelperOz5 } from "lib/devtools/packages/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

contract VaultTest is Test {
    ERC6551Registry public registry;
    VaultHubChainAccount public implementation;
    VaultHubChainFactory public factory;
    MockERC20 public currency;

    SecuritySource public securitySource;
    
    function setUp() public {

        registry = new ERC6551Registry();
        implementation = new VaultHubChainAccount();
        currency = new MockERC20("USDC", "USDC");
        securitySource = new SecuritySource(address(this));

        console.log("Registry address: ", address(registry));
        console.log("Implementation address: ", address(implementation));
        console.log("Owner address: ", address(this));
        factory = new VaultHubChainFactory(address(this), address(registry), address(implementation), address(currency));
        
    }

    function test_createVault() public {
        uint256 vaultId = factory.createVault();
        address account = factory.vaultHubChainAccounts(vaultId);

        address expectedAccount = registry.account(address(implementation), block.chainid, address(factory), vaultId, 0);

        address owner = factory.ownerOf(vaultId);

        assertEq(account, expectedAccount);
        assertEq(owner, address(this));
    }

    function test_sendEth() public {
        uint256 vaultId = factory.createVault();
        address payable account = payable(factory.vaultHubChainAccounts(vaultId));

        uint256 balanceBefore = account.balance;
        (bool success, ) = account.call{value: 0.0001 ether}("");

        assertEq(success, true);
        uint256 balanceAfter = account.balance;
        assertEq(balanceAfter, balanceBefore + 0.0001 ether);

        (success, ) = account.call{ value: 1 ether} (
            abi.encodeWithSignature("execute(address,uint256,bytes,uint256)", vm.addr(1), 0.0000011 ether, "", 0)
        );

        assertEq(success, true);

    }

    function test_whitelistTokens() public {

        MockERC20 token1 = new MockERC20("WBTC", "WBTC");
        MockERC20 token2 = new MockERC20("USDC", "USDC");

        //price feed mocked contracts
        MockChainlinkDataFeed priceFeed1 = new MockChainlinkDataFeed(6306055000000); // BTC / USD prices 8 decimals
        MockChainlinkDataFeed priceFeed2 = new MockChainlinkDataFeed(100000000); // USDC / USD prices 8 decimals

        //volatility feed mocked contracts
        MockChainlinkDataFeed volatilityFeed1 = new MockChainlinkDataFeed(67415); // BTC / USD  30 days volatitly 3 decimals on percentage -> 67415 = 67.415% vol
        MockChainlinkDataFeed volatilityFeed2 = new MockChainlinkDataFeed(0); // USDC / USD  30 days volatitly 3 decimals on percentage

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(token2);

        address[] memory priceFeeds = new address[](2);
        priceFeeds[0] = address(priceFeed1);
        priceFeeds[1] = address(priceFeed2);

        address[] memory volatilityFeeds = new address[](2);
        volatilityFeeds[0] = address(volatilityFeed1);
        volatilityFeeds[1] = address(volatilityFeed2);


        securitySource.setWhitelistedERC20Tokens(tokens, priceFeeds, volatilityFeeds);

        assertEq(securitySource.numberWhitelistedERC20Tokens(), 2);

        assertEq(securitySource.whitelistedERC20Tokens(0), address(token1));
        assertEq(securitySource.whitelistedERC20Tokens(1), address(token2));

        assertEq(securitySource.priceFeedsWhitelistedERC20Tokens(0), address(priceFeed1));
        assertEq(securitySource.priceFeedsWhitelistedERC20Tokens(1), address(priceFeed2));

        assertEq(securitySource.volatilityFeedsWhitelistedERC20Tokens(0), address(volatilityFeed1));
        assertEq(securitySource.volatilityFeedsWhitelistedERC20Tokens(1), address(volatilityFeed2));
    }

    function test_initialDeposit() public {

        uint256 vaultId = factory.createVault();
        address account = factory.vaultHubChainAccounts(vaultId);

        currency.mint(address(this), 1000 ether);
        currency.approve(payable(account), 1000 ether);

        VaultHubChainAccount(payable(account)).deposit(1000 ether);

        uint256 price = 1;

        assertEq(currency.balanceOf(account), 1000 ether);
        assertEq(VaultHubChainAccount(payable(account)).balanceOf(address(this)), 1000 ether / price);
    }

    function test_depositAfterWBTCDeposit() public {

        MockERC20 token1 = new MockERC20("WBTC", "WBTC");

        //price feed mocked contracts
        MockChainlinkDataFeed priceFeed1 = new MockChainlinkDataFeed(6306055000000); // BTC / USD prices 8 decimals
        MockChainlinkDataFeed priceFeed2 = new MockChainlinkDataFeed(100000000); // USDC / USD prices 8 decimals

        //volatility feed mocked contracts
        MockChainlinkDataFeed volatilityFeed1 = new MockChainlinkDataFeed(67415); // BTC / USD  30 days volatitly 3 decimals on percentage -> 67415 = 67.415% vol
        MockChainlinkDataFeed volatilityFeed2 = new MockChainlinkDataFeed(0); // USDC / USD  30 days volatitly 3 decimals on percentage

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(currency);

        address[] memory priceFeeds = new address[](2);
        priceFeeds[0] = address(priceFeed1);
        priceFeeds[1] = address(priceFeed2);

        address[] memory volatilityFeeds = new address[](2);
        volatilityFeeds[0] = address(volatilityFeed1);
        volatilityFeeds[1] = address(volatilityFeed2);

        securitySource.setWhitelistedERC20Tokens(tokens, priceFeeds, volatilityFeeds);

        factory.setSecuritySourceHubchain(address(securitySource));

        uint256 vaultId = factory.createVault();
        address account = factory.vaultHubChainAccounts(vaultId);

        currency.mint(address(this), 1000 ether);
        currency.approve(payable(account), 1000 ether);

        VaultHubChainAccount(payable(account)).deposit(1000 ether);

        uint256 price = 1;

        assertEq(currency.balanceOf(account), 1000  ether);
        assertEq(VaultHubChainAccount(payable(account)).balanceOf(address(this)), 1000 ether / price);

        //Send WBTC to the account

        token1.mint(account, 1 ether);

        (uint256 amount, ) = VaultHubChainAccount(payable(account)).evaluateTotalValue();

        uint256 amountExpected;

        for(uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = MockERC20(tokens[i]).balanceOf(account);
            (, int256 priceFromFeed, , , ) = MockChainlinkDataFeed(priceFeeds[i]).latestRoundData();
            amountExpected += balance * uint256(priceFromFeed) / 10 ** MockERC20(tokens[i]).decimals();
        }

        assertEq(amount, amountExpected);
    }
}
