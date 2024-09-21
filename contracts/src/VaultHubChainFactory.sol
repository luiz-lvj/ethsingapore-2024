// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import { IERC6551Registry } from "./interfaces/IERC6551Registry.sol";
import { VaultHubChainAccount } from "./VaultHubChainAccount.sol";
import { SecuritySource } from "./SecuritySource.sol";



contract VaultHubChainFactory is ERC721, Ownable {
    uint256 public vaultCounter;

    IERC6551Registry public registry;
    VaultHubChainAccount public implementation;
    SecuritySource public securitySource;
    
    ERC20 public currencyToken;

    mapping(uint256 => address) public vaultHubChainAccounts;

    //events
    event VaultCreated(address indexed owner, uint256 indexed vaultId, address indexed vaultAccount);
    event SecuritySourceSet(address indexed securitySource);


    constructor(address _initialOwner, address _register, address _implementation, address _currency) ERC721("VaultHubChain", "VHC") Ownable(_initialOwner)  {
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
}