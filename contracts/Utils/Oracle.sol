//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AggregatorV3.sol";

contract Oracle {
    address payable Owner;
    int256 price;

    AggregatorV3 priceFeed;

    modifier onlyOwner() {
        require(msg.sender == Owner, "onlyOwner");
        _;
    }

    constructor(address _AggregatorV3) {
        Owner = payable(msg.sender);
        priceFeed = AggregatorV3(_AggregatorV3);
    }

    function latestAnswer() internal {
        price = priceFeed.getLatestPrice();
    }

    function getLastPrice() external pure returns (uint256) {
        return uint256(1);
    }
}
