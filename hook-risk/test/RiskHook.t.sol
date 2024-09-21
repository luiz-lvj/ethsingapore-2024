// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import  {Test, console} from "forge-std/Test.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {RiskHook} from "../src/RiskHook.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";


import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {EasyPosm} from "./utils/EasyPosm.sol";
import {Fixtures} from "./utils/Fixtures.sol";

import { SecuritySource } from "../src/SecuritySource.sol";
import { MockChainlinkDataFeed } from "../src/mocks/MockChainlinkDataFeed.sol";
import { MockMultiVault } from "../src/mocks/MockMultiVault.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";


contract RiskHookTest is Test, Fixtures {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    RiskHook hook;
    PoolId poolId;

    uint256 tokenId;
    int24 tickLower;
    int24 tickUpper;

    SecuritySource securitySource;

    function setUp() public {
        // creates the pool manager, utility routers, and test tokens
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        deployAndApprovePosm(manager);

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(
                Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                    | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
            ) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
        );

        securitySource = new SecuritySource(address(this));
        bytes memory constructorArgs = abi.encode(manager, address(securitySource)); //Add all the necessary constructor arguments from the hook
        deployCodeTo("RiskHook.sol:RiskHook", constructorArgs, flags);
        hook = RiskHook(flags);

        // Create the pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(hook));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);
    }

    function testProvideLiquidity() public {

        address token1 = Currency.unwrap(currency0);
        address token2 = Currency.unwrap(currency1);

        whitelistTokensAndFeeds(token1, token2);

        provideLiquidity();
    }

    function testFailProvideLiquidity() public {
        provideLiquidity();
    }

    function testSwap() public {
        //Perform a test swap //

        address token1 = Currency.unwrap(currency0);
        address token2 = Currency.unwrap(currency1);
        

        whitelistTokensAndFeeds(token1, token2);

        provideLiquidity();

        address vault = createMultiVaultFromParameters(10000000000, 0, 70000);

        bool zeroForOne = true;
        int256 amountSpecified = -1e18; //negative number indicates exact input swap!
        bytes memory hookData = abi.encode(vault);
        BalanceDelta swapDelta = swap(key, zeroForOne, amountSpecified, hookData);
    }

    function testFailSwapNoLiquidity() public {
        //Perform a test swap //

        address token1 = Currency.unwrap(currency0);
        address token2 = Currency.unwrap(currency1);

        whitelistTokensAndFeeds(token1, token2);

        address vault = createMultiVaultFromParameters(50000, 10000000, 0);

        bool zeroForOne = true;
        int256 amountSpecified = -1e18; //negative number indicates exact input swap!
        bytes memory hookData = abi.encode(vault);
        BalanceDelta swapDelta = swap(key, zeroForOne, amountSpecified, hookData);

    }

    function testFailVolatilityExceedance() public {
        address token1 = Currency.unwrap(currency0);
        address token2 = Currency.unwrap(currency1);

        whitelistTokensAndFeeds(token1, token2);

        provideLiquidity();

        // Create a vault with max volatility lower than the expected deltaTotalVolatility
        address vault = createMultiVaultFromParameters(1, 0, 10); // Max volatility set very low

        // As token1 is more volatile than token2, zeroForOne = true increases total volatility and zeroForOne = false decreases volatility
        bool zeroForOne = false;
        int256 amountSpecified = -1e18; //negative number indicates exact input swap!
        bytes memory hookData = abi.encode(vault);
        swap(key, zeroForOne, amountSpecified, hookData); // Should fail due to volatility exceeding
    }

    function testSuccessVolatilityDueToZeroForOne() public {
        address token1 = Currency.unwrap(currency0);
        address token2 = Currency.unwrap(currency1);

        whitelistTokensAndFeeds(token1, token2);

        provideLiquidity();

        // Create a vault with max volatility lower than the expected deltaTotalVolatility
        address vault = createMultiVaultFromParameters(1, 0, 10); // Max volatility set very low

        // As token1 is more volatile than token2, zeroForOne = true increases total volatility and zeroForOne = false decreases volatility
        bool zeroForOne = true;
        int256 amountSpecified = -1e18; //negative number indicates exact input swap!
        bytes memory hookData = abi.encode(vault);
        swap(key, zeroForOne, amountSpecified, hookData); // Should fail due to volatility exceeding
    }


    // helpers
    function provideLiquidity() public {

        //Provide full-range liquidity to the pool
        tickLower = TickMath.minUsableTick(key.tickSpacing);
        tickUpper = TickMath.maxUsableTick(key.tickSpacing);

        uint128 liquidityAmount = 100e18;

        (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
            SQRT_PRICE_1_1,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            liquidityAmount
        );

        (tokenId,) = posm.mint(
            key,
            tickLower,
            tickUpper,
            liquidityAmount,
            amount0Expected + 1,
            amount1Expected + 1,
            address(this),
            block.timestamp,
            ZERO_BYTES
        );
        
    }

    function whitelistTokensAndFeeds(address token1, address token2) public{
        //price feed mocked contracts
        MockChainlinkDataFeed priceFeed1 = new MockChainlinkDataFeed(6306055000000); // BTC / USD prices 8 decimals
        MockChainlinkDataFeed priceFeed2 = new MockChainlinkDataFeed(100000000); // USDC / USD prices 8 decimals

        //volatility feed mocked contracts
        MockChainlinkDataFeed volatilityFeed1 = new MockChainlinkDataFeed(67415); // BTC / USD  30 days volatitly 3 decimals on percentage -> 67415 = 67.415% vol
        MockChainlinkDataFeed volatilityFeed2 = new MockChainlinkDataFeed(0); // USDC / USD  30 days volatitly 3 decimals on percentage

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(token2);

        address[] memory priceFeeds = new address[](2);
        priceFeeds[0] = address(priceFeed1);
        priceFeeds[1] = address(priceFeed2);

        address[] memory volatilityFeeds = new address[](2);
        volatilityFeeds[0] = address(volatilityFeed1);
        volatilityFeeds[1] = address(volatilityFeed2);

        securitySource.setWhitelistedERC20Tokens(tokens, priceFeeds, volatilityFeeds);
    }

    function createMultiVaultFromParameters(uint256 _totalValueInUSD, uint256 _totalValueInVolatility, uint256 _maxVolatility) public returns(address) {

        MockMultiVault vault = new MockMultiVault(_totalValueInUSD, _totalValueInVolatility, _maxVolatility);

        return address(vault);
    }

    function getDeltaTotalVolatility(uint256 amount0, uint256 amount1, int price0, int price1, int vol0, int vol1, bool zeroForOne) internal pure returns (int256) {
        uint256 value0 = amount0 * uint256(price0) * uint256(vol0);
        uint256 value1 = amount1 * uint256(price1) * uint256(vol1);

        int256 deltaTotalVolatility;

        if(zeroForOne){
            deltaTotalVolatility = int256(value1) - int256(value0);
        } else {
            deltaTotalVolatility = int256(value0) - int256(value1);
        }

        return deltaTotalVolatility;
    }

    function getPriceAndVol(address token) public view returns (int, int) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(securitySource.tokenToPriceFeed(token));
        AggregatorV3Interface volFeed = AggregatorV3Interface(securitySource.tokenToVolatilityFeed(token));

        

        (, int price, , , ) = priceFeed.latestRoundData();
        (, int vol, , , ) = volFeed.latestRoundData();

        return (price, vol);
    }

}
