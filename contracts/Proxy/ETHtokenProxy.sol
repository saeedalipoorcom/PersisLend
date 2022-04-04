//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Handler/Data/ETHHandlerDataStorage.sol";
import "../Model/InterestModel.sol";
import "../Manager/Contracts/Manager.sol";

contract ETHtokenProxy {
    address payable Owner;

    uint256 handlerID;
    string tokenName;

    uint256 constant unifiedPoint = 10**18;

    InterestModel InterestModelContract;
    ETHHandlerDataStorage DataStorageForHandlerContract;

    Manager ManagerContract;

    modifier OnlyOwner() {
        require(msg.sender == Owner, "OnlyOwner");
        _;
    }

    address marketHandler;

    constructor() {
        Owner = payable(msg.sender);
    }

    function setManagerContract(address _ManagerContract)
        external
        returns (bool)
    {
        ManagerContract = Manager(_ManagerContract);
        return true;
    }

    function setMarketHandler(address _marketHandler) external returns (bool) {
        marketHandler = _marketHandler;
        return true;
    }

    function setInterestModelContract(address _InterestModelContract)
        external
        returns (bool)
    {
        InterestModelContract = InterestModel(_InterestModelContract);
        return true;
    }

    function setDataStorageForHandlerContract(
        address _DataStorageForHandlerContract
    ) external returns (bool) {
        DataStorageForHandlerContract = ETHHandlerDataStorage(
            _DataStorageForHandlerContract
        );
        return true;
    }

    function settokenName(string memory _tokenName) external returns (bool) {
        tokenName = _tokenName;
        return true;
    }

    function getHandlerID() external view returns (uint256) {
        return handlerID;
    }

    function sethandlerID(uint256 _handlerID) external returns (bool) {
        handlerID = _handlerID;
        return true;
    }

    function deposit(uint256 _amountToDeposit) external payable returns (bool) {
        bool _result;

        bytes memory _returnData;
        bytes memory _data = abi.encodeWithSignature(
            "deposit(uint256)",
            _amountToDeposit
        );

        (_result, _returnData) = marketHandler.delegatecall(_data);

        require(_result, string(_returnData));
        return _result;
    }

    function withdraw(uint256 _amountToWithdraw)
        external
        payable
        returns (bool)
    {
        bool _result;

        bytes memory _returnData;
        bytes memory _data = abi.encodeWithSignature(
            "withdraw(uint256)",
            _amountToWithdraw
        );

        (_result, _returnData) = marketHandler.delegatecall(_data);

        require(_result, string(_returnData));
        return _result;
    }

    function handlerProxy(bytes memory data)
        external
        returns (bool, bytes memory)
    {
        bool result;
        bytes memory returnData;
        (result, returnData) = marketHandler.delegatecall(data);
        require(result, string(returnData));
        return (result, returnData);
    }

    function getAmounts(address payable _userAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return DataStorageForHandlerContract.getAmounts(_userAddress);
    }

    function getMarketInterestLimits()
        external
        view
        returns (uint256, uint256)
    {
        return DataStorageForHandlerContract.getMarketInterestLimits();
    }
}
