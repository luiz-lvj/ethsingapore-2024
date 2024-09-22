// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";


import { VaultHubChainFactory } from "../contracts/VaultHubChainFactory.sol";
import { VaultHubChainAccount } from "../contracts/VaultHubChainAccount.sol";



contract  CreateVaultAndSetSpokeChain is Script {


    VaultHubChainFactory public factoryHubChain;

    function setUp() public {}

    function run() public {

        //uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        address factoryHubChainSepolia = 0x22599F1d29F97F66ECdAAfD03dc8bE60ac45575D;


        factoryHubChain = VaultHubChainFactory(factoryHubChainSepolia);

        uint256 vaultId = factoryHubChain.createVault();

        VaultHubChainAccount vault = VaultHubChainAccount(payable(factoryHubChain.vaultHubChainAccounts(vaultId)));

        uint256 lineaSepoliaChainId = 84532;

        vault.registerNewSpokeChain{ value: 250000000000000000 }(vaultId, lineaSepoliaChainId);


        vm.stopBroadcast();
        
    }
}