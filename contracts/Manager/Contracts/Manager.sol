//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Data/ManagerDataStorage.sol";
import "../../Utils/oracleProxy.sol";
import "../../Proxy/tokenProxy.sol";

import "../../Utils/SafeMath.sol";

contract Manager {
    using SafeMath for uint256;

    address public Owner;

    bool public Emergency = false;

    ManagerDataStorage ManagerDataStorageContract;
    oracleProxy OracleContract;

    modifier OnlyOwner() {
        require(msg.sender == Owner, "OnlyOwner");
        _;
    }

    struct UserAssetsInfo {
        uint256 depositAssetSum;
        uint256 borrowAssetSum;
        uint256 marginCallLimitSum;
        uint256 depositAssetBorrowLimitSum;
        uint256 depositAsset;
        uint256 borrowAsset;
        uint256 price;
        uint256 callerPrice;
        uint256 depositAmount;
        uint256 borrowAmount;
        uint256 borrowLimit;
        uint256 marginCallLimit;
        uint256 callerBorrowLimit;
        uint256 userBorrowableAsset;
        uint256 withdrawableAsset;
    }

    mapping(address => UserAssetsInfo) UserAssetsInfoMapping;

    uint256 public tokenHandlerLength;

    mapping(address => address) handlerToProxyMapping;

    constructor() {
        Owner = msg.sender;
    }

    function handlerToProxyMappingFunc(address _handler, address _proxy)
        external
        returns (bool)
    {
        handlerToProxyMapping[_handler] = _proxy;
        return true;
    }

    function setOracleContract(address _OracleContract)
        external
        OnlyOwner
        returns (bool)
    {
        OracleContract = oracleProxy(_OracleContract);
        return true;
    }

    function setManagerDataStorageContract(address _ManagerDataStorageContract)
        external
        OnlyOwner
        returns (bool)
    {
        ManagerDataStorageContract = ManagerDataStorage(
            _ManagerDataStorageContract
        );
        return true;
    }

    function registerNewHandler(uint256 _handlerID, address _handlerAddress)
        external
        OnlyOwner
        returns (bool)
    {
        return _registerNewHandler(_handlerID, _handlerAddress);
    }

    function _registerNewHandler(uint256 _handlerID, address _handlerAddress)
        internal
        returns (bool)
    {
        ManagerDataStorageContract.setTokenHandler(_handlerID, _handlerAddress);
        tokenHandlerLength = tokenHandlerLength + 1;
        return true;
    }

    function applyInterestHandlers(
        address payable _userAddress,
        uint256 _handlerID
    ) external returns (uint256) {
        UserAssetsInfo memory userAssetsInfo;

        bool _Support;
        address _Address;

        for (uint256 ID = 1; ID <= tokenHandlerLength; ID++) {
            (_Support, _Address) = ManagerDataStorageContract
                .getTokenHandlerInfo(ID);
            if (_Support) {
                address _ProxyAddress = handlerToProxyMapping[_Address];
                tokenProxy _TokenProxyContract = tokenProxy(_ProxyAddress);

                (
                    ,
                    ,
                    userAssetsInfo.depositAmount,
                    userAssetsInfo.borrowAmount
                ) = _TokenProxyContract.getAmounts(_userAddress);

                (
                    userAssetsInfo.borrowLimit,
                    userAssetsInfo.marginCallLimit
                ) = _TokenProxyContract.getMarketInterestLimits();

                if (ID == _handlerID) {
                    userAssetsInfo.price = OracleContract.getTokenPrice(ID);
                    userAssetsInfo.callerPrice = userAssetsInfo.price;
                    userAssetsInfo.callerBorrowLimit = userAssetsInfo
                        .borrowLimit;
                }

                if (
                    userAssetsInfo.depositAmount > 0 ||
                    userAssetsInfo.borrowAmount > 0
                ) {
                    if (ID != _handlerID) {
                        userAssetsInfo.price = OracleContract.getTokenPrice(ID);
                    }

                    if (userAssetsInfo.depositAmount > 0) {
                        userAssetsInfo.depositAsset = userAssetsInfo
                            .depositAmount
                            .unifiedMul(userAssetsInfo.price);

                        userAssetsInfo
                            .depositAssetBorrowLimitSum = userAssetsInfo
                            .depositAssetBorrowLimitSum
                            .add(
                                userAssetsInfo.depositAsset.unifiedMul(
                                    userAssetsInfo.borrowLimit
                                )
                            );

                        userAssetsInfo.marginCallLimitSum = userAssetsInfo
                            .marginCallLimitSum
                            .add(
                                userAssetsInfo.depositAsset.unifiedMul(
                                    userAssetsInfo.marginCallLimit
                                )
                            );

                        userAssetsInfo.depositAssetSum = userAssetsInfo
                            .depositAssetSum
                            .add(userAssetsInfo.depositAsset);
                    }

                    if (userAssetsInfo.borrowAmount > 0) {
                        userAssetsInfo.borrowAsset = userAssetsInfo
                            .borrowAmount
                            .unifiedMul(userAssetsInfo.price);

                        userAssetsInfo.borrowAssetSum = userAssetsInfo
                            .borrowAssetSum
                            .add(userAssetsInfo.borrowAsset);
                    }
                }
            }
        }

        if (
            userAssetsInfo.depositAssetBorrowLimitSum >
            userAssetsInfo.borrowAssetSum
        ) {
            userAssetsInfo.userBorrowableAsset = userAssetsInfo
                .depositAssetBorrowLimitSum
                .sub(userAssetsInfo.borrowAssetSum);

            userAssetsInfo.withdrawableAsset = userAssetsInfo
                .depositAssetBorrowLimitSum
                .sub(userAssetsInfo.borrowAssetSum)
                .unifiedDiv(userAssetsInfo.callerBorrowLimit);
        }

        UserAssetsInfoMapping[_userAddress] = userAssetsInfo;

        return userAssetsInfo.userBorrowableAsset;
    }

    function getUserDepositAmount(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].depositAmount;
    }

    function getUserBorrowAmount(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].borrowAmount;
    }

    function getUserDepositAssetSum(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].depositAssetSum;
    }

    function getUserBorrowAssetSum(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].borrowAssetSum;
    }

    function getUserMarginCallLimitSum(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].marginCallLimitSum;
    }

    function getUserDepositAssetBorrowLimitSum(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].depositAssetBorrowLimitSum;
    }

    function getUserDepositAsset(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].depositAsset;
    }

    function getUserBorrowAsset(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].borrowAsset;
    }

    function getUserBorrowLimit(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].borrowLimit;
    }

    function getUserMarginCallLimit(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].marginCallLimit;
    }

    function getUserCallerBorrowLimit(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].callerBorrowLimit;
    }

    function getUserBorrowableAsset(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].userBorrowableAsset;
    }

    function getUserWithdrawableAsset(address _userAddress)
        external
        view
        returns (uint256)
    {
        return UserAssetsInfoMapping[_userAddress].withdrawableAsset;
    }
}
