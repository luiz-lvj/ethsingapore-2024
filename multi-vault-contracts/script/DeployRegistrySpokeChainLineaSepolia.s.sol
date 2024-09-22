// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import { ERC6551RegistrySpokeChain } from "../contracts/RegistrySpokeChain.sol";
import { VaultSpokeChainAccount } from "../contracts/VaultSpokeChainAccount.sol";


contract DeployRegistrySpokeChainLineaSepolia is Script {

    ERC6551RegistrySpokeChain public registrySpokeChain;
    VaultSpokeChainAccount public implementationSpokeChain;
    
    


    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address owner = 0x000ef5F21dC574226A06C76AAE7060642A30eB74;
        address endpointLineaSepolia = 0x6EDCE65403992e310A62460808c4b910D972f10f;

        address hubChainFactory =  0x22599F1d29F97F66ECdAAfD03dc8bE60ac45575D;
        uint32 sepoliaEid = 40287;

        registrySpokeChain = new ERC6551RegistrySpokeChain(owner, endpointLineaSepolia);
        implementationSpokeChain = new VaultSpokeChainAccount();

        registrySpokeChain.setHubChainFactoryPeer(sepoliaEid, hubChainFactory);


        console.log("-------- LINEA SEPOLIA DEPLOYMENT --------");
        console.log("Registry address: ", address(registrySpokeChain));
        console.log("Implementation address: ", address(implementationSpokeChain));
        

        vm.stopBroadcast();
        
    }
}