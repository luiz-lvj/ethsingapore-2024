// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMultiVault {
    function getTotalValueInUSD() external view returns(uint256);

    function getTotalValueInVolatility() external view returns(uint256);

    function getMaxVolatility() external view returns(uint256);
}


contract MockMultiVault  is IMultiVault {

    uint256 public totalValueInUSD;
    uint256 public totalValueInVolatility;
    uint256 public maxVolatility;

    constructor(uint256 _totalValueInUSD, uint256 _totalValueInVolatility, uint256 _maxVolatility) {
        totalValueInUSD = _totalValueInUSD;
        totalValueInVolatility = _totalValueInVolatility;
        maxVolatility = _maxVolatility;
    }

    function getTotalValueInUSD() external view override returns(uint256) {
        return totalValueInUSD;
    }

    function getTotalValueInVolatility() external view override returns(uint256) {
        return totalValueInVolatility;
    }

    function getMaxVolatility() external view override returns(uint256) {
        return maxVolatility;
    }

}