// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";


import { ERC6551Registry } from "../contracts/ERC6551Registry.sol";
import { VaultHubChainAccount } from "../contracts/VaultHubChainAccount.sol";
import { VaultHubChainFactory } from "../contracts/VaultHubChainFactory.sol";
import { MockERC20 } from "../contracts/mocks/MockERC20.sol";

import { SecuritySource } from "../contracts/SecuritySource.sol";

contract DeployHubChainSepolia is Script {
    
    ERC6551Registry public registryHubChain;
    VaultHubChainAccount public implementationHubChain;
    VaultHubChainFactory public factoryHubChain;
    MockERC20 public currencyHubChain;

    SecuritySource public securitySourceHubChain;



    function setUp() public {}

    function run() public {

        //uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        registryHubChain = new ERC6551Registry();
        implementationHubChain = new VaultHubChainAccount();
        currencyHubChain = new MockERC20("USDC", "USDC");

        address owner = 0x000ef5F21dC574226A06C76AAE7060642A30eB74;
        address endpointSepolia = 0x6EDCE65403992e310A62460808c4b910D972f10f;

        securitySourceHubChain = new SecuritySource(owner);

        factoryHubChain = new VaultHubChainFactory(owner, address(registryHubChain), address(implementationHubChain), address(currencyHubChain), endpointSepolia);

        console.log("-------- SEPOLIA DEPLOYMENT --------");
        console.log("Registry address: ", address(registryHubChain));
        console.log("Implementation address: ", address(implementationHubChain));
        console.log("currency address: ", address(currencyHubChain));
        console.log("Owner address: ", owner);
        console.log("Endpoint Sepolia address: ", endpointSepolia);
        console.log("Security Source address: ", address(securitySourceHubChain));
        console.log("Factory address: ", address(factoryHubChain));

        vm.stopBroadcast();
        
    }
}