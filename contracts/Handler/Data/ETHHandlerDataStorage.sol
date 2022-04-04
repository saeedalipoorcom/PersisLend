//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../Utils/SafeMath.sol";
import "../../Utils/Oracle.sol";

// functions for reservedAmount, reservedAddr, interestModelAddress is not set !
// we need to set markethandler address for data storage !

contract ETHHandlerDataStorage {
    using SafeMath for uint256;

    address payable Owner;

    address marketHandlerAddress;

    Oracle OracleContract;

    uint256 constant unifiedPoint = 10**18;
    // uint256 public liquidityLimit = unifiedPoint;
    uint256 public limitOfAction = 100000 * unifiedPoint;

    bool emergency = false;

    int256 reservedAmount;
    // address payable reservedAddr;
    address interestModelAddress;

    uint256 lastUpdateBlock;
    uint256 inactiveActionDelta;

    uint256 actionDepositEXR;
    uint256 actionBorrowEXR;

    uint256 public globalDepositEXR;
    uint256 public globalBorrowEXR;

    uint256 public depositTotalAmount;
    uint256 public borrowTotalAmount;

    struct IntraUser {
        bool userAccessed;
        uint256 userDeposit;
        uint256 userBorrow;
        uint256 userDepositEXR;
        uint256 userBorrowEXR;
    }
    mapping(address => IntraUser) IntraUserMapping;

    struct MarketInterestModelParameters {
        uint256 borrowLimit;
        uint256 marginCallLimit;
        uint256 minimumInterestRate;
        uint256 liquiditySensitivity;
    }
    MarketInterestModelParameters interestParams;

    modifier OnlyOwner() {
        require(msg.sender == Owner, "OnlyOwner");
        _;
    }

    constructor(
        uint256 _borrowLimit,
        uint256 _marginCallLimit,
        uint256 _minimumInterestRate,
        uint256 _liquiditySensitivity
    ) {
        Owner = payable(msg.sender);
        initialEXR();

        interestParams.borrowLimit = _borrowLimit;
        interestParams.liquiditySensitivity = _liquiditySensitivity;
        interestParams.marginCallLimit = _marginCallLimit;
        interestParams.minimumInterestRate = _minimumInterestRate;
    }

    function setOracleContract(address _OracleContract)
        external
        returns (bool)
    {
        OracleContract = Oracle(_OracleContract);
        return true;
    }

    function initialEXR() internal {
        uint256 currentBlockNumber = block.number;
        actionDepositEXR = unifiedPoint;
        actionBorrowEXR = unifiedPoint;
        globalDepositEXR = unifiedPoint;
        globalBorrowEXR = unifiedPoint;

        lastUpdateBlock = currentBlockNumber - 1;
        inactiveActionDelta = lastUpdateBlock;
    }

    function ownerShipTransfer(address payable _owner)
        public
        OnlyOwner
        returns (bool)
    {
        require(_owner != address(0), "Address is 0");
        Owner = _owner;
        return true;
    }

    function getOwner() external view returns (address) {
        return Owner;
    }

    function setCircuitBreaker(bool _emergency)
        external
        OnlyOwner
        returns (bool)
    {
        emergency = _emergency;
        return true;
    }

    function setNewUser(address payable _userAddress) external returns (bool) {
        IntraUserMapping[_userAddress].userAccessed = true;
        IntraUserMapping[_userAddress].userDepositEXR = unifiedPoint;
        IntraUserMapping[_userAddress].userBorrowEXR = unifiedPoint;
        return true;
    }

    function setuserAccesse(address payable _userAddress, bool _newStatus)
        external
        returns (bool)
    {
        IntraUserMapping[_userAddress].userAccessed = _newStatus;
        return true;
    }

    function addDepositTotalAmount(uint256 _amountToAdd)
        external
        returns (bool)
    {
        depositTotalAmount = depositTotalAmount.add(_amountToAdd);
        return true;
    }

    function subDepositTotalAmount(uint256 _amountToSub)
        external
        returns (bool)
    {
        depositTotalAmount = depositTotalAmount.sub(_amountToSub);
        return true;
    }

    function addborrowTotalAmount(uint256 _amountToAdd)
        external
        returns (bool)
    {
        borrowTotalAmount = borrowTotalAmount.add(_amountToAdd);
        return true;
    }

    function subborrowTotalAmount(uint256 _amountToSub)
        external
        returns (bool)
    {
        borrowTotalAmount = borrowTotalAmount.sub(_amountToSub);
        return true;
    }

    function addIntraUserDepositAmount(
        address payable _userAddress,
        uint256 _amountToAdd
    ) external returns (bool) {
        IntraUserMapping[_userAddress].userDeposit = IntraUserMapping[
            _userAddress
        ].userDeposit.add(_amountToAdd);
        return true;
    }

    function subIntraUserDepositAmount(
        address payable _userAddress,
        uint256 _amountToSub
    ) external returns (bool) {
        IntraUserMapping[_userAddress].userDeposit = IntraUserMapping[
            _userAddress
        ].userDeposit.sub(_amountToSub);
        return true;
    }

    function addIntraUserBorrowAmount(
        address payable _userAddress,
        uint256 _amountToAdd
    ) external returns (bool) {
        IntraUserMapping[_userAddress].userBorrow = IntraUserMapping[
            _userAddress
        ].userBorrow.add(_amountToAdd);
        return true;
    }

    function subIntraUserBorrowAmount(
        address payable _userAddress,
        uint256 _amountToSub
    ) external returns (bool) {
        IntraUserMapping[_userAddress].userBorrow = IntraUserMapping[
            _userAddress
        ].userBorrow.sub(_amountToSub);
        return true;
    }

    function addDepositAmount(
        address payable _userAddress,
        uint256 _amountToAdd
    ) external returns (bool) {
        IntraUserMapping[_userAddress].userDeposit = IntraUserMapping[
            _userAddress
        ].userDeposit.add(_amountToAdd);
        depositTotalAmount = depositTotalAmount.add(_amountToAdd);
        return true;
    }

    function subDepositAmount(
        address payable _userAddress,
        uint256 _amountToSub
    ) external returns (bool) {
        IntraUserMapping[_userAddress].userDeposit = IntraUserMapping[
            _userAddress
        ].userDeposit.sub(_amountToSub);
        depositTotalAmount = depositTotalAmount.sub(_amountToSub);
        return true;
    }

    function addBorrowAmount(address payable _userAddress, uint256 _amountToAdd)
        external
        returns (bool)
    {
        IntraUserMapping[_userAddress].userBorrow = IntraUserMapping[
            _userAddress
        ].userBorrow.add(_amountToAdd);
        borrowTotalAmount = borrowTotalAmount.add(_amountToAdd);
        return true;
    }

    function subBorrowAmount(address payable _userAddress, uint256 _amountToSub)
        external
        returns (bool)
    {
        IntraUserMapping[_userAddress].userBorrow = IntraUserMapping[
            _userAddress
        ].userBorrow.sub(_amountToSub);
        borrowTotalAmount = borrowTotalAmount.sub(_amountToSub);
        return true;
    }

    function getUserAmounts(address payable _userAddress)
        external
        view
        returns (uint256, uint256)
    {
        return (
            IntraUserMapping[_userAddress].userDeposit,
            IntraUserMapping[_userAddress].userBorrow
        );
    }

    function getHandlerAmounts() external view returns (uint256, uint256) {
        return (depositTotalAmount, borrowTotalAmount);
    }

    function updateAmounts(
        address payable _userAddress,
        uint256 _depositTotalAmount,
        uint256 _borrowTotalAmount,
        uint256 _depositAmount,
        uint256 _borrowAmount
    ) external returns (bool) {
        depositTotalAmount = _depositTotalAmount;
        borrowTotalAmount = _borrowTotalAmount;
        IntraUserMapping[_userAddress].userBorrow = _borrowAmount;
        IntraUserMapping[_userAddress].userDeposit = _depositAmount;
        return true;
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
        return (
            depositTotalAmount,
            borrowTotalAmount,
            IntraUserMapping[_userAddress].userDeposit,
            IntraUserMapping[_userAddress].userBorrow
        );
    }

    function setBlocks(uint256 _lastUpdateBlock, uint256 _inactiveActionDelta)
        external
        returns (bool)
    {
        lastUpdateBlock = _lastUpdateBlock;
        inactiveActionDelta = _inactiveActionDelta;
        return true;
    }

    function setLastUpdateBlock(uint256 _lastUpdateBlock)
        external
        returns (bool)
    {
        lastUpdateBlock = _lastUpdateBlock;
        return true;
    }

    function setInactiveActionDelta(uint256 _inactiveActionDelta)
        external
        returns (bool)
    {
        inactiveActionDelta = _inactiveActionDelta;
        return true;
    }

    function syncEXR() external returns (bool) {
        actionDepositEXR = globalDepositEXR;
        actionBorrowEXR = globalBorrowEXR;
        return true;
    }

    function getActionEXR() external view returns (uint256, uint256) {
        return (actionDepositEXR, actionBorrowEXR);
    }

    function setActionEXR(uint256 _actionDepositEXR, uint256 _actionBorrowEXR)
        external
        returns (bool)
    {
        actionBorrowEXR = _actionBorrowEXR;
        actionDepositEXR = _actionDepositEXR;
        return true;
    }

    function setEXR(
        address payable _userAddress,
        uint256 _globalDepositEXR,
        uint256 _globalBorrowEXR
    ) external returns (bool) {
        globalDepositEXR = _globalDepositEXR;
        globalBorrowEXR = _globalBorrowEXR;
        IntraUserMapping[_userAddress].userDepositEXR = _globalDepositEXR;
        IntraUserMapping[_userAddress].userBorrowEXR = _globalBorrowEXR;
        return true;
    }

    function getUserEXR(address payable _userAddress)
        external
        view
        returns (uint256, uint256)
    {
        return (
            IntraUserMapping[_userAddress].userDepositEXR,
            IntraUserMapping[_userAddress].userBorrowEXR
        );
    }

    function setUserEXR(
        address payable _userAddress,
        uint256 _globalDepositEXR,
        uint256 _globalBorrowEXR
    ) external returns (bool) {
        IntraUserMapping[_userAddress].userDepositEXR = _globalDepositEXR;
        IntraUserMapping[_userAddress].userBorrowEXR = _globalBorrowEXR;
        return true;
    }

    function getGlobalEXR() external view returns (uint256, uint256) {
        return (globalBorrowEXR, globalDepositEXR);
    }

    function setMarketHandlerAddress(address _marketHandlerAddress)
        external
        returns (bool)
    {
        marketHandlerAddress = _marketHandlerAddress;
        return true;
    }

    function getTotalBorrowAmount() external view returns (uint256) {
        return borrowTotalAmount;
    }

    function getTotalDepositAmount() external view returns (uint256) {
        return depositTotalAmount;
    }

    function getLastUpdateBlock() external view returns (uint256) {
        return lastUpdateBlock;
    }

    function getInactiveActionDelta() external view returns (uint256) {
        return inactiveActionDelta;
    }

    function getUserAccessed(address payable _userAddress)
        external
        view
        returns (bool)
    {
        return IntraUserMapping[_userAddress].userAccessed;
    }

    function getIntraUserBorrowAmount(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        return IntraUserMapping[_userAddress].userBorrow;
    }

    function getIntraUserDepositAmount(address payable _userAddress)
        external
        view
        returns (uint256)
    {
        return IntraUserMapping[_userAddress].userDeposit;
    }

    function getGlobalBorrowEXR() external view returns (uint256) {
        return globalBorrowEXR;
    }

    function getGlobalDepositEXR() external view returns (uint256) {
        return globalDepositEXR;
    }

    function getActionDepositEXR() external view returns (uint256) {
        return actionDepositEXR;
    }

    function getActionBorrowEXR() external view returns (uint256) {
        return actionBorrowEXR;
    }

    function getMarketHandlerAddress() external view returns (address) {
        return marketHandlerAddress;
    }

    function getMarketInterestLimits()
        external
        view
        returns (uint256, uint256)
    {
        return (interestParams.borrowLimit, interestParams.marginCallLimit);
    }

    function getMarketInterestBorrowLimit() external view returns (uint256) {
        return interestParams.borrowLimit;
    }

    function getMarketInterestMarginCallLimit()
        external
        view
        returns (uint256)
    {
        return interestParams.marginCallLimit;
    }

    function getMinimumInterestRate() external view returns (uint256) {
        return interestParams.minimumInterestRate;
    }

    function getLiquiditySensitivity() external view returns (uint256) {
        return interestParams.liquiditySensitivity;
    }

    function setBorrowLimit(uint256 _borrowLimit) external returns (bool) {
        interestParams.borrowLimit = _borrowLimit;
        return true;
    }

    function setMarginCallLimit(uint256 _marginCallLimit)
        external
        returns (bool)
    {
        interestParams.marginCallLimit = _marginCallLimit;
        return true;
    }

    function setMinimumInterestRate(uint256 _minimumInterestRate)
        external
        returns (bool)
    {
        interestParams.minimumInterestRate = _minimumInterestRate;
        return true;
    }

    function setLiquiditySensitivity(uint256 _liquiditySensitivity)
        external
        returns (bool)
    {
        interestParams.liquiditySensitivity = _liquiditySensitivity;
        return true;
    }

    function getUserDepositValue(address _userAddress)
        external
        view
        returns (uint256)
    {
        uint256 _userDepositAmount = IntraUserMapping[_userAddress].userDeposit;
        uint256 _updateOraclePrice = getLastMarketPrice();

        return _userDepositAmount * _updateOraclePrice;
    }

    function getLastMarketPrice() internal view returns (uint256) {
        return OracleContract.latestAnswer();
    }
}
