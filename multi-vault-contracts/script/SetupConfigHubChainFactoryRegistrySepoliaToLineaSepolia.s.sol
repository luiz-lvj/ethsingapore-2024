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

        address factoryHubChainSepolia = 0x22599F1d29F97F66ECdAAfD03dc8bE60ac45575D;
        uint32 lineaSepoliaEid = 40245;
        address lineaSepoliaRegistryAddress = 0x3546914261a14D476671B02498420aDBbE7cA69A;
        address lineaSepoliaImplementationAddress = 0xA261F923654Eb93Ab6c35D285d58c8a01D42F792;

        uint256 lineaSepoliaChainId = 84532;


        factoryHubChain = VaultHubChainFactory(factoryHubChainSepolia);

        factoryHubChain.setSpokeChainConfig(lineaSepoliaChainId, lineaSepoliaRegistryAddress, lineaSepoliaImplementationAddress, lineaSepoliaEid);
        
        vm.stopBroadcast();
        
    }
}