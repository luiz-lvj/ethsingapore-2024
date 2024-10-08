// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./interfaces/IERC6551Account.sol";
import "./interfaces/IERC6551Executable.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";

import { VaultHubChainFactory } from "./VaultHubChainFactory.sol";
import { SecuritySource } from "./SecuritySource.sol";

import { console } from "forge-std/Test.sol";

contract VaultHubChainAccount is ERC20, IERC165, IERC1271, IERC6551Account, IERC6551Executable {
    receive() external payable {}

    uint256 public state;
    VaultHubChainFactory public factory;
    SecuritySource public securitySource;
    ERC20 public currencyToken;
    bool public isInitialized;

    uint256 public valueHubChainAccountUSD;
    uint256 public valueHubChainAccountVolatility;

    uint256 public totalValueInUSD;
    uint256 public totalValueInVolatility;

    uint256 public maxVolatility;

    mapping(uint256 => address) public spokeChainsImplementationsAccounts; // ChainId to SpokeChainAccount


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
    event SpokeChainRegistered(address indexed spokeChainAccount, uint256 indexed spokeChainId);

    constructor()  ERC20("HUBChain", "HUBChain") {

    }

    //CUSTOM FUNCTIONS
    function initializeAccount(address _factory, address _currency, address _securitySource) public onlyNotInitialized {
        require(_isValidSigner(msg.sender), "Invalid signer");
        currencyToken = ERC20(_currency);
        factory = VaultHubChainFactory(_factory);
        securitySource = SecuritySource(_securitySource);
        isInitialized = true;
        emit Initialized(_factory, _currency);
    }


    function registerNewSpokeChain(uint256 vaultId, uint256 chainId) public payable {
        require(_isValidSigner(msg.sender), "Invalid signer");
        require(spokeChainsImplementationsAccounts[chainId] == address(0), "Spoke chain already registered");

        address newAccount = factory.createSpokeChainAccount{ value: msg.value  }(vaultId, chainId);

        spokeChainsImplementationsAccounts[chainId] = newAccount;

        emit SpokeChainRegistered(newAccount, chainId);

    }

    function evaluateHubChainTokens() public returns(uint256, uint256) {

        valueHubChainAccountUSD = 0;
        valueHubChainAccountVolatility = 0;
        uint256 numberWhiteListedTokens = securitySource.numberWhitelistedERC20Tokens();

        for(uint256 i = 0; i < numberWhiteListedTokens; i++) {
            ERC20 erc20Token = ERC20(securitySource.whitelistedERC20Tokens(i));
            AggregatorV3Interface priceFeed = AggregatorV3Interface(securitySource.priceFeedsWhitelistedERC20Tokens(i));
            AggregatorV3Interface volFeed = AggregatorV3Interface(securitySource.volatilityFeedsWhitelistedERC20Tokens(i));

            uint256 balance = erc20Token.balanceOf(address(this));

            int256 price;
            int256 vol;

            (, price, , , ) = priceFeed.latestRoundData();
            (, vol, , , ) = volFeed.latestRoundData();

            valueHubChainAccountUSD += balance * uint256(price) / 10 ** erc20Token.decimals();
            valueHubChainAccountVolatility += balance * uint256(vol) / 10 ** erc20Token.decimals();
        }

        return (valueHubChainAccountUSD, valueHubChainAccountVolatility);
    }


    function evaluateTotalValue() public returns(uint256, uint256) {
        // Evaluate from hub chain and all spoke chains

        //TODO - Implement spoke chains evaluation

        (uint256 hubChainValue, uint256 hubChainVol) = evaluateHubChainTokens();
        console.log("HubChainValue: ", hubChainValue);
        console.log("HubChainVol: ", hubChainVol);

        totalValueInUSD = hubChainValue;
        totalValueInVolatility = hubChainVol;

        return (totalValueInUSD, totalValueInVolatility);
    }

    function getTotalVaultVolatility() public view returns(uint256) {
        return totalValueInVolatility/totalValueInUSD;
    }

    function getTotalValueInUSD() external view returns(uint256) {
        return totalValueInUSD;
    }

    function getTotalValueInVolatility() external view returns(uint256) {
        return totalValueInVolatility;
    }

    function getMaxVolatility() external view returns(uint256) {
        return maxVolatility;
    }

    
    function getQuotaPrice() public view returns (uint256) {
        if(totalSupply() == 0) {
            return 1;
        }
        return totalValueInUSD * 10 ** decimals() / totalSupply();
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