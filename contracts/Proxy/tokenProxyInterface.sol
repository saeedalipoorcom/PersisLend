//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface tokenProxyInterface {
    function setManagerContract(address _ManagerContract)
        external
        returns (bool);

    function setMarketHandler(address _marketHandler) external returns (bool);

    function setInterestModelContract(address _InterestModelContract)
        external
        returns (bool);

    function setDataStorageForHandlerContract(
        address _DataStorageForHandlerContract
    ) external returns (bool);

    function settokenName(string memory _tokenName) external returns (bool);

    function getHandlerID() external returns (uint256);

    function sethandlerID(uint256 _handlerID) external returns (bool);

    function deposit(uint256 _amountToDeposit) external payable returns (bool);

    function withdraw(uint256 _amountToWithdraw)
        external
        payable
        returns (bool);

    function borrow(uint256 _amountToBorrow) external returns (bool);

    function repay(uint256 _amountToRePay) external payable returns (bool);

    function getAmounts(address payable _userAddress)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getMarketInterestLimits() external returns (uint256, uint256);
}
