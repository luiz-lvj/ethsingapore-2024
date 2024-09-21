// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC6551Executable.sol";

import { VaultHubChainFactory } from "./VaultHubChainFactory.sol";

contract VaultHubChainAccount is ERC20, IERC165, IERC1271, IERC6551Account, IERC6551Executable {
    receive() external payable {}


    uint256 public state;
    VaultHubChainFactory public factory;
    ERC20 public currencyToken;
    bool public isInitialized;


    //modifiers
    modifier onlyFactory() {
        require(msg.sender == address(factory), "Only factory can call this function");
        _;
    }

    modifier onlyNotInitialized() {
        require(!isInitialized, "Already initialized");
        _;
    }

    //events
    event Initialized(address indexed factory, address indexed currency);
    event Deposit(address indexed depositor, uint256 amountInTokenCurrency, uint256 amountInQuota);

    constructor()  ERC20("TEST", "TEST") {
        state = 0;
    }

    //CUSTOM FUNCTIONS
    function initializeAccount(address _factory, address _currency) public onlyNotInitialized {
        require(_isValidSigner(msg.sender), "Invalid signer");
        currencyToken = ERC20(_currency);
        factory = VaultHubChainFactory(_factory);
        isInitialized = true;
        emit Initialized(_factory, _currency);
    }

    function evaluateHubChainTokens() public view returns(uint256) {
        return (address(factory), address(currencyToken));
    }

    function getQuotaPrice() public pure returns (uint256) {
        return 3;
    }

    function deposit(uint256 _amountInCurrencyToken) public {
        require(_isValidSigner(msg.sender), "Invalid signer");
        
        uint256 amountInQuota = _amountInCurrencyToken / getQuotaPrice();

        currencyToken.transferFrom(msg.sender, address(this), _amountInCurrencyToken);

        _mint(msg.sender, amountInQuota);


        emit Deposit(msg.sender, _amountInCurrencyToken, amountInQuota);
    }


    // STANDARD ERC6551 FUNCTIONS
    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation
    ) external payable returns (bytes memory result) {
        require(_isValidSigner(msg.sender), "Invalid signer");
        require(operation == 0, "Only call operations are supported");


        ++state;

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function isValidSigner(address signer, bytes calldata) external view returns (bytes4) {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }

        return bytes4(0);
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId ||
            interfaceId == type(IERC6551Executable).interfaceId);
    }

    function token()
        public
        view
        returns (
            uint256,
            address,
            uint256
        )
    {
        bytes memory footer = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function _isValidSigner(address signer) internal view returns (bool) {
        return signer == owner();
    }
}