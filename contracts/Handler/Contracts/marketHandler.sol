//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Data/HandlerDataStorage.sol";
import "../../Model/InterestModel.sol";
import "../../Manager/Contracts/Manager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract marketHandler {
    event Deposit(
        address _depositedFrom,
        uint256 _amountToDeposit,
        uint256 _handlerID
    );
    event OwnershipTransferred(address owner, address newOwner);

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

    modifier OnlyManager() {
        require(msg.sender == address(ManagerContract), "OnlyManager");
        _;
    }

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

    function setCircuitBreaker(bool _emergency)
        external
        OnlyOwner
        returns (bool)
    {
        DataStorageForHandlerContract.setCircuitBreaker(_emergency);
        return true;
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

    function getTokenName() external view returns (string memory) {
        return tokenName;
    }

    function gethandlerID() external view returns (uint256) {
        return handlerID;
    }

    function getOwnerAddress() external view returns (address) {
        return Owner;
    }

    function deposit(uint256 _amountToDeposit) external payable returns (bool) {
        require(msg.value == 0);
        address payable _userAddress = payable(msg.sender);
        uint256 _handlerID = handlerID;

        DataStorageForHandlerContract.addDepositAmount(
            _userAddress,
            _amountToDeposit
        );

        DAIErc20.transferFrom(_userAddress, address(this), _amountToDeposit);
        ManagerContract.applyInterestHandlers(_userAddress, _handlerID);

        return true;
    }

    function withdraw(uint256 _amountToWithdraw)
        external
        payable
        returns (bool)
    {
        require(msg.value == 0);
        address payable _userAddress = payable(msg.sender);
        uint256 _handlerID = handlerID;

        uint256 _userBorrowableAsset;
        uint256 _withdrawableAsset;
        uint256 _Price;

        (
            _userBorrowableAsset,
            _withdrawableAsset,
            ,
            ,
            ,
            _Price
        ) = ManagerContract.applyInterestHandlers(_userAddress, _handlerID);

        uint256 _finalWithdrawableAmount = _getUserActionMaxWithdrawAmount(
            _userAddress,
            _amountToWithdraw,
            _withdrawableAsset
        );

        require(
            unifiedMul(_finalWithdrawableAmount, _Price) <=
                DataStorageForHandlerContract.limitOfAction()
        );

        DataStorageForHandlerContract.subDepositAmount(
            _userAddress,
            _amountToWithdraw
        );

        DAIErc20.transfer(_userAddress, _amountToWithdraw);
        ManagerContract.applyInterestHandlers(_userAddress, _handlerID);

        return true;
    }

    function borrow(uint256 _amountToBorrow) external payable returns (bool) {
        require(msg.value == 0);
        address payable _userAddress = payable(msg.sender);
        uint256 _handlerID = handlerID;

        uint256 _userBorrowableAsset;
        uint256 _withdrawableAsset;
        uint256 _Price;

        (
            _userBorrowableAsset,
            _withdrawableAsset,
            ,
            ,
            ,
            _Price
        ) = ManagerContract.applyInterestHandlers(_userAddress, _handlerID);

        uint256 _finalBorrowableAmount = _getUserActionMaxBorrowAmount(
            _amountToBorrow,
            _userBorrowableAsset
        );

        require(
            unifiedMul(_finalBorrowableAmount, _Price) <=
                DataStorageForHandlerContract.limitOfAction()
        );

        DataStorageForHandlerContract.addBorrowAmount(
            _userAddress,
            _finalBorrowableAmount
        );

        DAIErc20.transfer(_userAddress, _finalBorrowableAmount);
        ManagerContract.applyInterestHandlers(_userAddress, _handlerID);

        return true;
    }

    function repay(uint256 _amountToRepay) external payable returns (bool) {
        require(msg.value == 0);
        address payable _userAddress = payable(msg.sender);
        uint256 _handlerID = handlerID;

        uint256 _userTotalBorrowAmount = DataStorageForHandlerContract
            .getIntraUserBorrowAmount(_userAddress);

        if (_userTotalBorrowAmount < _amountToRepay) {
            _amountToRepay = _userTotalBorrowAmount;
        }

        DataStorageForHandlerContract.subBorrowAmount(
            _userAddress,
            _amountToRepay
        );

        DAIErc20.transferFrom(_userAddress, address(this), _amountToRepay);
        ManagerContract.applyInterestHandlers(_userAddress, _handlerID);

        return true;
    }

    function applyInterest(address payable _userAddress)
        external
        OnlyManager
        returns (uint256, uint256)
    {
        return _applyInterest(_userAddress);
    }

    function _applyInterest(address payable _userAddress)
        internal
        returns (uint256, uint256)
    {
        _checkIfUserIsNew(_userAddress);
        syncAndUpdateBlocks();
        return updateInterestFactorsForUserAndMarket(_userAddress);
    }

    function updateInterestFactorsForUserAndMarket(address payable _userAddress)
        internal
        returns (uint256, uint256)
    {
        bool depositNegativeFlag;
        uint256 deltaDepositAmount;
        uint256 globalDepositEXR;

        bool borrowNegativeFlag;
        uint256 deltaBorrowAmount;
        uint256 globalBorrowEXR;

        (
            depositNegativeFlag,
            deltaDepositAmount,
            globalDepositEXR,
            borrowNegativeFlag,
            deltaBorrowAmount,
            globalBorrowEXR
        ) = InterestModelContract._getInterestAmountsForUser(
            _userAddress,
            address(DataStorageForHandlerContract)
        );

        DataStorageForHandlerContract.setEXR(
            _userAddress,
            globalDepositEXR,
            globalBorrowEXR
        );

        uint256 userDepositAmount;
        uint256 userBorrowAmount;

        (userDepositAmount, userBorrowAmount) = _setInterestAmount(
            _userAddress,
            depositNegativeFlag,
            deltaDepositAmount,
            borrowNegativeFlag,
            deltaBorrowAmount
        );

        return (userDepositAmount, userBorrowAmount);
    }

    function _checkIfUserIsNew(address payable _userAddress)
        internal
        returns (bool)
    {
        bool isUserNew = DataStorageForHandlerContract.getUserAccessed(
            _userAddress
        );

        if (isUserNew) {
            return false;
        }

        DataStorageForHandlerContract.setuserAccesse(_userAddress, true);
        (uint256 globaBEXR, uint256 globalDEXR) = DataStorageForHandlerContract
            .getGlobalEXR();
        DataStorageForHandlerContract.setUserEXR(
            _userAddress,
            globalDEXR,
            globaBEXR
        );
        return true;
    }

    function syncAndUpdateBlocks() internal returns (bool) {
        uint256 lastUpdateBlock = DataStorageForHandlerContract
            .getLastUpdateBlock();
        uint256 currentBlockNumber = block.number;
        uint256 deltaBlock = currentBlockNumber - lastUpdateBlock;

        if (deltaBlock > 0) {
            DataStorageForHandlerContract.setBlocks(
                currentBlockNumber,
                deltaBlock
            );
            DataStorageForHandlerContract.syncEXR();
            return true;
        }

        return false;
    }

    function _setInterestAmount(
        address payable _userAddress,
        bool _depositNegativeFlag,
        uint256 _deltaDepositAmount,
        bool borrowNegativeFlag,
        uint256 _deltaBorrowAmount
    ) internal returns (uint256, uint256) {
        uint256 depositTotalAmount;
        uint256 userDepositAmount;
        uint256 borrowTotalAmount;
        uint256 userBorrowAmount;

        (
            depositTotalAmount,
            userDepositAmount,
            borrowTotalAmount,
            userBorrowAmount
        ) = _getAmountWithInterest(
            _userAddress,
            _depositNegativeFlag,
            _deltaDepositAmount,
            borrowNegativeFlag,
            _deltaBorrowAmount
        );

        DataStorageForHandlerContract.updateAmounts(
            _userAddress,
            depositTotalAmount,
            borrowTotalAmount,
            userDepositAmount,
            userBorrowAmount
        );

        return (userDepositAmount, userBorrowAmount);
    }

    function _getAmountWithInterest(
        address payable userAddr,
        bool depositNegativeFlag,
        uint256 deltaDepositAmount,
        bool borrowNegativeFlag,
        uint256 deltaBorrowAmount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 depositTotalAmount;
        uint256 userDepositAmount;
        uint256 borrowTotalAmount;
        uint256 userBorrowAmount;
        (
            depositTotalAmount,
            borrowTotalAmount,
            userDepositAmount,
            userBorrowAmount
        ) = DataStorageForHandlerContract.getAmounts(userAddr);

        if (depositNegativeFlag) {
            depositTotalAmount = sub(depositTotalAmount, deltaDepositAmount);
            userDepositAmount = sub(userDepositAmount, deltaDepositAmount);
        } else {
            depositTotalAmount = add(depositTotalAmount, deltaDepositAmount);
            userDepositAmount = add(userDepositAmount, deltaDepositAmount);
        }

        if (borrowNegativeFlag) {
            borrowTotalAmount = sub(borrowTotalAmount, deltaBorrowAmount);
            userBorrowAmount = sub(userBorrowAmount, deltaBorrowAmount);
        } else {
            borrowTotalAmount = add(borrowTotalAmount, deltaBorrowAmount);
            userBorrowAmount = add(userBorrowAmount, deltaBorrowAmount);
        }

        return (
            depositTotalAmount,
            userDepositAmount,
            borrowTotalAmount,
            userBorrowAmount
        );
    }

    function _getUserActionMaxWithdrawAmount(
        address payable _userAddress,
        uint256 _amountToWithdraw,
        uint256 _withdrawableAsset
    ) internal view returns (uint256) {
        uint256 _userDepositedAmount = DataStorageForHandlerContract
            .getIntraUserDepositAmount(_userAddress);

        uint256 _marketHandlerAvLiquidity = _getMarketHandlerAvLiquidity();

        uint256 minAmount = _userDepositedAmount;

        if (minAmount > _amountToWithdraw) {
            minAmount = _amountToWithdraw;
        }

        if (minAmount > _withdrawableAsset) {
            minAmount = _withdrawableAsset;
        }

        if (minAmount > _marketHandlerAvLiquidity) {
            minAmount = _marketHandlerAvLiquidity;
        }

        return minAmount;
    }

    function _getMarketHandlerAvLiquidity() internal view returns (uint256) {
        uint256 _marketTotalDeposit = DataStorageForHandlerContract
            .getTotalDepositAmount();
        uint256 _marketTotalBorrow = DataStorageForHandlerContract
            .getTotalBorrowAmount();

        if (_marketTotalDeposit == 0) {
            return 0;
        }

        if (_marketTotalDeposit < _marketTotalBorrow) {
            return 0;
        }

        return sub(_marketTotalDeposit, _marketTotalBorrow);
    }

    function _getUserActionMaxBorrowAmount(
        uint256 _amountToBorrow,
        uint256 _userBorrowableAsset
    ) internal view returns (uint256) {
        uint256 _marketHandlerAvLimLiquidity = _getMarketHandlerAvLimLiquidity();

        uint256 minAmount = _amountToBorrow;

        if (minAmount > _marketHandlerAvLimLiquidity) {
            minAmount = _marketHandlerAvLimLiquidity;
        }

        if (minAmount > _userBorrowableAsset) {
            minAmount = _userBorrowableAsset;
        }

        return minAmount;
    }

    function _getMarketHandlerAvLimLiquidity() internal view returns (uint256) {
        uint256 _marketTotalDeposit = DataStorageForHandlerContract
            .getTotalDepositAmount();
        uint256 _marketTotalBorrow = DataStorageForHandlerContract
            .getTotalBorrowAmount();

        if (_marketTotalDeposit == 0) {
            return 0;
        }

        uint256 _liquidityTotalDeposit = unifiedMul(
            _marketTotalDeposit,
            DataStorageForHandlerContract.liquidityLimit()
        );

        if (_liquidityTotalDeposit < _marketTotalBorrow) {
            return 0;
        }

        return sub(_liquidityTotalDeposit, _marketTotalBorrow);
    }

    /* ******************* Safe Math ******************* */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return _sub(a, b, "sub overflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mul(a, b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "div by zero");
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mod(a, b, "mod by zero");
    }

    function _sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function _mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require((c / a) == b, "mul overflow");
        return c;
    }

    function _div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function _mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, unifiedPoint), b, "unified div by zero");
    }

    function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, b), unifiedPoint, "unified mul by zero");
    }

    function signedAdd(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            ((b >= 0) && (c >= a)) || ((b < 0) && (c < a)),
            "SignedSafeMath: addition overflow"
        );
        return c;
    }

    function signedSub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            ((b >= 0) && (c <= a)) || ((b < 0) && (c > a)),
            "SignedSafeMath: subtraction overflow"
        );
        return c;
    }
}
