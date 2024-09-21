// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

import {Currency} from "v4-core/src/types/Currency.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";

import { SecuritySource } from "./SecuritySource.sol";

import "forge-std/Test.sol";


interface MultiVault {
    function getTotalValueInUSD() external view returns(uint256);

    function getTotalValueInVolatility() external view returns(uint256);

    function getMaxVolatility() external view returns(uint256);
}

contract RiskHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------

    //Custom errors
    error CurrencyNotWhitelisted(address token);
    error VolatilityExceeded(uint256 totalValueInVolatility, uint256 maxVolatility);
    error NoTotalVallueInUSD();

    SecuritySource securitySource;

    constructor(IPoolManager _poolManager, address _securitySource) BaseHook(_poolManager) {
        securitySource = SecuritySource(_securitySource);
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: true,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // -----------------------------------------------
    // NOTE: see IHooks.sol for function documentation
    // -----------------------------------------------

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external
        override view
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        //address wallet = IUniversalRouter(sender).msgSender();

        // address wallet = abi.decode(hookData, (address));

        address currency0 = Currency.unwrap(key.currency0);
        address currency1 = Currency.unwrap(key.currency1);

        if(!securitySource.isWhitelistedERC20Token(currency0)) {
            revert CurrencyNotWhitelisted(currency0);
        }
        if(!securitySource.isWhitelistedERC20Token(currency1)) {
            revert CurrencyNotWhitelisted(currency1);
        }

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapParams, BalanceDelta delta, bytes calldata hookData )
        external
        override view
        returns (bytes4, int128)
    {

        (int price0, int vol0) = getPriceAndVol(Currency.unwrap(key.currency0));
        (int price1, int vol1) = getPriceAndVol(Currency.unwrap(key.currency1));

        bool zeroForOne = swapParams.zeroForOne;
        
        int256 deltaTotalVolatility = getDeltaTotalVolatility(absDelta(delta.amount0()),absDelta(delta.amount1()), price0, price1, vol0, vol1, zeroForOne);

        MultiVault walletVault = MultiVault(abi.decode(hookData, (address)));

        (uint256 totalValueInUSD, uint256 totalValueInVolatility, uint256 maxVolatility) = getVaultDetails(walletVault);

        if(totalValueInUSD <= 0){
            revert NoTotalVallueInUSD();
        }


        int256 newVolatilityValue = (int256(totalValueInVolatility) + deltaTotalVolatility)/int256(totalValueInUSD);

        if(newVolatilityValue > int256(maxVolatility)){
            revert VolatilityExceeded(totalValueInVolatility, maxVolatility);
        }

        return (BaseHook.afterSwap.selector, 0);
    }

    function beforeAddLiquidity(
        address,
        PoolKey calldata key,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override view returns (bytes4) {

        address currency0 = Currency.unwrap(key.currency0);
        address currency1 = Currency.unwrap(key.currency1);

        if(!securitySource.isWhitelistedERC20Token(currency0)) {
            revert CurrencyNotWhitelisted(currency0);
        }
        if(!securitySource.isWhitelistedERC20Token(currency1)) {
            revert CurrencyNotWhitelisted(currency1);
        }

        return BaseHook.beforeAddLiquidity.selector;
    }

    function beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override pure returns (bytes4) {
        return BaseHook.beforeRemoveLiquidity.selector;
    }

    function getPriceAndVol(address token) internal view returns (int, int) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(securitySource.tokenToPriceFeed(token));
        AggregatorV3Interface volFeed = AggregatorV3Interface(securitySource.tokenToVolatilityFeed(token));

        (, int price, , , ) = priceFeed.latestRoundData();
        (, int vol, , , ) = volFeed.latestRoundData();

        return (price, vol);
    }

    function getDeltaTotalVolatility(uint256 amount0, uint256 amount1, int price0, int price1, int vol0, int vol1, bool zeroForOne) internal pure returns (int256) {
        uint256 value0 = calculateValue(amount0, price0, vol0);
        uint256 value1 = calculateValue(amount1, price1, vol1);

        int256 deltaTotalVolatility;

        if(zeroForOne){
            deltaTotalVolatility = int256(value1) - int256(value0);
        } else {
            deltaTotalVolatility = int256(value0) - int256(value1);
        }

        return deltaTotalVolatility;
    }

    function getVaultDetails(MultiVault vault) internal view returns(uint256, uint256, uint256) {
        return(vault.getTotalValueInUSD(), vault.getTotalValueInVolatility(), vault.getMaxVolatility());
    }

    // Further reduce stack usage by moving volatility calculation into its own function
    function calculateValue(uint256 amount, int price, int vol) internal pure returns (uint256) {
        return amount * uint256(price) * uint256(vol);
    }

    // Helper to get absolute value of delta amounts
    function absDelta(int128 delta) internal pure returns (uint128) {
        return delta > 0 ? uint128(delta) : uint128(-delta);
    }
}
