// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { ERC6551Registry } from "../src/ERC6551Registry.sol";
import { VaultHubChainAccount } from "../src/VaultHubChainAccount.sol";
import { VaultHubChainFactory } from "../src/VaultHubChainFactory.sol";
import { MockERC20 } from "../src/mocks/MockERC20.sol";

contract VaultTest is Test {
    ERC6551Registry public registry;
    VaultHubChainAccount public implementation;
    VaultHubChainFactory public factory;
    MockERC20 public currency;
    
    function setUp() public {

        registry = new ERC6551Registry();
        implementation = new VaultHubChainAccount();
        currency = new MockERC20("USDC", "USDC");

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

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(token2);

        factory.setWhitelistedERC20Tokens(tokens);

        assertEq(factory.whitelistedERC20Tokens(0), address(token1));
        assertEq(factory.whitelistedERC20Tokens(1), address(token2));
    }

    function test_deposit() public {
        uint256 vaultId = factory.createVault();
        address account = factory.vaultHubChainAccounts(vaultId);

        currency.mint(address(this), 1000 ether);
        currency.approve(payable(account), 1000 ether);

        VaultHubChainAccount(payable(account)).deposit(1000 ether);

        uint256 price = VaultHubChainAccount(payable(account)).getQuotaPrice();

        assertEq(currency.balanceOf(account), 1000 ether);
        assertEq(VaultHubChainAccount(payable(account)).balanceOf(address(this)), 1000 ether / price);

    }
}
