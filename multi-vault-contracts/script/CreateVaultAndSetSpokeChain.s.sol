// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";


import { VaultHubChainFactory } from "../contracts/VaultHubChainFactory.sol";
import { VaultHubChainAccount } from "../contracts/VaultHubChainAccount.sol";



contract  SetupConfigHubChainFactoryRegistrySepoliaToLineaSepolia is Script {


    VaultHubChainFactory public factoryHubChain;

    function setUp() public {}

    function run() public {

        //uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        address factoryHubChainSepolia = 0xAF6D8B4577b61A3F389f96D9932156Ea9632CcC8;


        factoryHubChain = VaultHubChainFactory(factoryHubChainSepolia);

        uint256 vaultId = factoryHubChain.createVault();

        VaultHubChainAccount vault = VaultHubChainAccount(payable(factoryHubChain.vaultHubChainAccounts(vaultId)));

        uint256 lineaSepoliaChainId = 59141;

        vault.registerNewSpokeChain{ value: 100000000000000000 }(vaultId, lineaSepoliaChainId);






        
        
        vm.stopBroadcast();
        
    }
}