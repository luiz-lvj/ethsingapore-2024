// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { IERC6551Registry } from "./interfaces/IERC6551Registry.sol";
import { VaultHubChainAccount } from "./VaultHubChainAccount.sol";
import { SecuritySource } from "./SecuritySource.sol";

import { OApp, MessagingFee, Origin } from "@layerzerolabs/oapp-evm/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/oapp-evm/oapp/OAppSender.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/oapp/libs/OAppOptionsType3.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/oapp/libs/OptionsBuilder.sol";



contract VaultHubChainFactory is Ownable, OApp, OAppOptionsType3, ERC721 {

    //using OptionsBuilder for bytes;

    uint256 public vaultCounter;

    IERC6551Registry public registry;
    VaultHubChainAccount public implementation;
    SecuritySource public securitySource;
    
    ERC20 public currencyToken;
    mapping(uint256 => address) public vaultHubChainAccounts;

    //omnichain mappings
    mapping(uint256 => address) public spokeChainsRegistries; // chainId to RegistrySpokeChain
    mapping(uint256 => address) public spokeChainsImplementations; // chainId to VaultSpokeChainAccount


    //events
    event VaultCreated(address indexed owner, uint256 indexed vaultId, address indexed vaultAccount);
    event SecuritySourceSet(address indexed securitySource);

    //TODO OApp initializer
    constructor(address _initialOwner, address _register, address _implementation, address _currency) ERC721("VaultHubChain", "VHC") OApp(_initialOwner, _initialOwner) Ownable(_initialOwner)  {
        registry = IERC6551Registry(_register);
        implementation = VaultHubChainAccount(payable(_implementation));
        currencyToken = ERC20(_currency);
    }

    function setSecuritySourceHubchain(address _securitySource) public onlyOwner {
        securitySource = SecuritySource(_securitySource);
        emit SecuritySourceSet(_securitySource);
    }

    function createVault() public returns (uint256){
        uint256 vaultId = vaultCounter;

        vaultCounter++;

        _mint(address(this), vaultId);

        address vaultAccount = registry.createAccount(
            address(implementation),
            block.chainid,
            address(this),
            vaultId,
            0,
            ""
        );

        VaultHubChainAccount(payable(vaultAccount)).initializeAccount(address(this), address(currencyToken), address(securitySource));

        _transfer(address(this), msg.sender, vaultId);

        vaultHubChainAccounts[vaultId] = vaultAccount;

        emit VaultCreated(msg.sender, vaultId, vaultAccount);

        return vaultId;

    }


    function createSpokeChainAccount(uint256 vaultId, uint256 chainId) public {
        require(_msgSender() == vaultHubChainAccounts[vaultId], "Only vault account can call this function");
        bytes memory options = combineOptions(_dstEid, _msgType, _extraSendOptions);

        uint256 GAS_LIMIT = 1000000; // Gas limit for the executor
        uint256 MSG_VALUE = 0; // msg.value for the lzReceive() function on destination in wei

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, MSG_VALUE);

        // _lzSend(
        //     1,
        //     encodeMessage(spokeChainsImplementations[chainId], chainId, address(this), vaultId)
            

        // );




    }

    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        uint256 vaultId = abi.decode(payload, (uint256));
    }

    function encodeMessage(
        address erc6551implementationTarget,
        uint256 chainId,
        address tokenContract,
        uint256 vaultId
        ) public pure returns (bytes memory) {

        return abi.encode(erc6551implementationTarget, chainId, tokenContract, vaultId);
    }
     
}