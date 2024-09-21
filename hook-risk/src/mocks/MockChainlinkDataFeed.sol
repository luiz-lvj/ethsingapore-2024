// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";


contract MockChainlinkDataFeed is AggregatorV3Interface {

    int256 public mockedAnswer;

    constructor(int256 _answer) {
        mockedAnswer = _answer;
    }
    
    
    function latestRoundData()
    external
    view override
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound){
        return (0, mockedAnswer, 0, 0, 0);

    }

    function getRoundData(
        uint80 _roundId
    ) external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound){
        return (_roundId, mockedAnswer, 0, 0, 0);
    }

    function decimals() external pure override returns (uint8){
        return 8;
    }

    function description() external pure override returns (string memory){
        return "Mocked Chainlink Data Feed";
    }

    function version() external pure override returns (uint256){
        return 0;
    }


    
}