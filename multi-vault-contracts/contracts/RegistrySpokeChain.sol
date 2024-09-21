// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IERC6551Registry.sol";

import { OApp, MessagingFee, Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { MessagingReceipt } from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";



library ERC6551BytecodeLib {
    function getCreationCode(
        address implementation_,
        uint256 chainId_,
        address tokenContract_,
        uint256 tokenId_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt_, chainId_, tokenContract_, tokenId_)
            );
    }
}

contract ERC6551Registry is  OApp, IERC6551Registry {
    error InitializationFailed();


    constructor() OApp(msg.sender, msg.sender) Ownable(msg.sender)  {}

    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (address implementation, uint256 chainId, address tokenContract, uint256 tokenId) = decodeMessage(payload);
        
        address newAccount = createAccountWithoutInitData(implementation, chainId, tokenContract, tokenId, 0);

        
    }

    function decodeMessage(bytes calldata encodedMessage) public pure returns (address implementation, uint256 chainId, address tokenContract, uint256 tokenId) {

        (implementation, chainId, tokenContract, tokenId) = abi.decode(encodedMessage, (address, uint256, address, uint256));
        
        return (implementation, chainId, tokenContract, tokenId);
    }


    function createAccountWithoutInitData(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) public returns (address) {
        bytes memory code = ERC6551BytecodeLib.getCreationCode(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt
        );

        address _account = Create2.computeAddress(bytes32(salt), keccak256(code));

        if (_account.code.length != 0) return _account;

        emit AccountCreated(_account, implementation, chainId, tokenContract, tokenId, salt);

        _account = Create2.deploy(0, bytes32(salt), code);

        return _account;
    }
    

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) public returns (address) {
        bytes memory code = ERC6551BytecodeLib.getCreationCode(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt
        );

        address _account = Create2.computeAddress(bytes32(salt), keccak256(code));

        if (_account.code.length != 0) return _account;

        emit AccountCreated(_account, implementation, chainId, tokenContract, tokenId, salt);

        _account = Create2.deploy(0, bytes32(salt), code);

        if (initData.length != 0) {
            (bool success, ) = _account.call(initData);
            if (!success) revert InitializationFailed();
        }

        return _account;
    }

    function account(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            ERC6551BytecodeLib.getCreationCode(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt
            )
        );

        return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }
}