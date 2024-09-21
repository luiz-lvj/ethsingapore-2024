// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";


import { VaultHubChainFactory } from "../contracts/VaultHubChainFactory.sol";



contract  SetupConfigHubChainFactoryRegistrySepoliaToLineaSepolia is Script {
    


    VaultHubChainFactory public factoryHubChain;




    function setUp() public {}

    function run() public {

        //uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        address factoryHubChainSepolia = 0xc9A98C1697B7F46d2074bf8aFEE41F516cAbDCd0;
        uint32 lineaSepoliaEid = 40287;
        address lineaSepoliaRegistryAddress = 0x7aB14fBC0D7790C78a48aFE5ae99F6ef27C390d5;
        address lineaSepoliaImplementationAddress = 0x897Ad29e1c4649Dbe4a6b76CC249b7688deb9415;

        uint256 lineaSepoliaChainId = 59141;


        factoryHubChain = VaultHubChainFactory(factoryHubChainSepolia);

        factoryHubChain.setSpokeChainConfig(lineaSepoliaChainId, lineaSepoliaRegistryAddress, lineaSepoliaImplementationAddress, lineaSepoliaEid);
        
        vm.stopBroadcast();
        
    }
}