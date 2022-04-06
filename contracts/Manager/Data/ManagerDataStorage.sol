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

    modifier OnlyManager() {
        require(msg.sender == ManagerContract, "OnlyManager");
        _;
    }

    constructor() {
        Owner = msg.sender;
    }

    function setManagerContract(address _ManagerContract)
        external
        OnlyOwner
        returns (bool)
    {
        ManagerContract = _ManagerContract;
        return true;
    }

    function setTokenHandler(uint256 handlerID, address handlerAddr)
        external
        OnlyManager
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
