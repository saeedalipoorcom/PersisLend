//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Handler/Data/HandlerDataStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Model/InterestModel.sol";

import "../Manager/Contracts/Manager.sol";

contract tokenProxy {
    address payable Owner;

    uint256 handlerID;
    string tokenName;

    uint256 constant unifiedPoint = 10**18;

    InterestModel InterestModelContract;
    HandlerDataStorage DataStorageForHandlerContract;
    IERC20 DAIErc20;

    Manager ManagerContract;

    modifier OnlyOwner() {
        require(msg.sender == Owner, "OnlyOwner");
        _;
    }

    address marketHandler;

    constructor(address _DAIErc20) {
        Owner = payable(msg.sender);
        DAIErc20 = IERC20(_DAIErc20);
    }

    function setManagerContract(address _ManagerContract)
        external
        OnlyOwner
        returns (bool)
    {
        ManagerContract = Manager(_ManagerContract);
        return true;
    }

    function setMarketHandler(address _marketHandler)
        external
        OnlyOwner
        returns (bool)
    {
        marketHandler = _marketHandler;
        return true;
    }

    function setInterestModelContract(address _InterestModelContract)
        external
        OnlyOwner
        returns (bool)
    {
        InterestModelContract = InterestModel(_InterestModelContract);
        return true;
    }

    function setDataStorageForHandlerContract(
        address _DataStorageForHandlerContract
    ) external OnlyOwner returns (bool) {
        DataStorageForHandlerContract = HandlerDataStorage(
            _DataStorageForHandlerContract
        );
        return true;
    }

    function settokenName(string memory _tokenName)
        external
        OnlyOwner
        returns (bool)
    {
        tokenName = _tokenName;
        return true;
    }

    function getHandlerID() external view returns (uint256) {
        return handlerID;
    }

    function sethandlerID(uint256 _handlerID)
        external
        OnlyOwner
        returns (bool)
    {
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
