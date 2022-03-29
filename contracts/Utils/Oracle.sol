//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Oracle {
    address payable Owner;

    int256 price;

    modifier onlyOwner() {
        require(msg.sender == Owner, "onlyOwner");
        _;
    }

    constructor(int256 _price) {
        Owner = payable(msg.sender);
        price = _price;
    }

    function latestAnswer() external view returns (uint256) {
        return uint256(price);
    }

    function setPrice(int256 _price) public onlyOwner {
        price = _price;
    }
}
