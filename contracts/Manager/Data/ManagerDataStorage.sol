//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ManagerDataStorage {
    address public Owner;
    address ManagerContract;

    struct TokenHandler {
        address addr;
        bool support;
        bool exist;
    }

    mapping(uint256 => TokenHandler) tokenHandlers;
    uint256[] private tokenHandlerList;

    modifier OnlyOwner() {
        require(msg.sender == Owner, "OnlyOwner");
        _;
    }

    constructor() {
        Owner = msg.sender;
    }

    function setTokenHandler(uint256 handlerID, address handlerAddr)
        external
        returns (bool)
    {
        TokenHandler memory handler;
        handler.addr = handlerAddr;
        handler.exist = true;
        handler.support = true;
        tokenHandlers[handlerID] = handler;
        tokenHandlerList.push(handlerID);

        return true;
    }

    function getTokenHandlerInfo(uint256 handlerID)
        external
        view
        returns (bool, address)
    {
        return (
            tokenHandlers[handlerID].support,
            tokenHandlers[handlerID].addr
        );
    }

    function getTokenHandlerAddr(uint256 handlerID)
        external
        view
        returns (address)
    {
        return tokenHandlers[handlerID].addr;
    }

    function getTokenHandlerExist(uint256 handlerID)
        external
        view
        returns (bool)
    {
        return tokenHandlers[handlerID].exist;
    }

    function getTokenHandlerSupport(uint256 handlerID)
        external
        view
        returns (bool)
    {
        return tokenHandlers[handlerID].support;
    }

    function getTokenHandlerID(uint256 index) external view returns (uint256) {
        return tokenHandlerList[index];
    }
}
