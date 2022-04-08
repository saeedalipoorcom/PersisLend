//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// we can use different safemath

import "../Handler/Data/HandlerDataStorage.sol";
import "../Utils/SafeMath.sol";

// i used 1000 blocks per year , you can change it !

contract InterestModel {
    using SafeMath for uint256;

    address payable Owner;

    uint256 blocksPerYear = 1000;
    uint256 constant unifiedPoint = 10**18;

    uint256 minimumRate;
    uint256 basicSensitivity;
    uint256 jumpPoint;
    uint256 jumpSensitivity;
    uint256 spreadRate;

    struct userInterestModel {
        uint256 SIR;
        uint256 BIR;
        uint256 depositTotalAmount;
        uint256 borrowTotalAmount;
        uint256 userDepositAmount;
        uint256 userBorrowAmount;
        uint256 deltaDepositAmount;
        uint256 deltaBorrowAmount;
        uint256 globalDepositEXR;
        uint256 globalBorrowEXR;
        uint256 userDepositEXR;
        uint256 userBorrowEXR;
        uint256 actionDepositEXR;
        uint256 actionBorrowEXR;
        uint256 deltaDepositEXR;
        uint256 deltaBorrowEXR;
        bool depositNegativeFlag;
        bool borrowNegativeFlag;
    }

    modifier OnlyOwner() {
        require(msg.sender == Owner, "OnlyOwner");
        _;
    }

    constructor(
        uint256 _minRate,
        uint256 _jumpPoint,
        uint256 _basicSensitivity,
        uint256 _jumpSensitivity,
        uint256 _spreadRate
    ) {
        Owner = payable(msg.sender);
        minimumRate = _minRate;
        basicSensitivity = _basicSensitivity;
        jumpPoint = _jumpPoint;
        jumpSensitivity = _jumpSensitivity;
        spreadRate = _spreadRate;
    }

    function _getInterestAmountsForUser(
        address payable _userAddress,
        address _DataStorageForHandler
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        HandlerDataStorage _HandlerDataStorage = HandlerDataStorage(
            _DataStorageForHandler
        );

        uint256 _Delta = _HandlerDataStorage.getInactiveActionDelta();
        (
            uint256 _DepositActionEXR,
            uint256 _BorrowActionEXR
        ) = _HandlerDataStorage.getActionEXR();

        return
            _calcInterestModelForUser(
                _userAddress,
                _DataStorageForHandler,
                _Delta,
                _DepositActionEXR,
                _BorrowActionEXR
            );
    }

    function _calcInterestModelForUser(
        address payable _userAddress,
        address _DataStorageForHandler,
        uint256 _Delta,
        uint256 _DepositActionEXR,
        uint256 _BorrowActionEXR
    )
        internal
        view
        returns (
            bool,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        userInterestModel memory _userInterestModel;
        HandlerDataStorage _HandlerDataStorage = HandlerDataStorage(
            _DataStorageForHandler
        );

        (
            _userInterestModel.depositTotalAmount,
            _userInterestModel.borrowTotalAmount,
            _userInterestModel.userDepositAmount,
            _userInterestModel.userBorrowAmount
        ) = _HandlerDataStorage.getAmounts(_userAddress);

        (
            _userInterestModel.userDepositEXR,
            _userInterestModel.userBorrowEXR
        ) = _HandlerDataStorage.getUserEXR(_userAddress);

        (_userInterestModel.SIR, _userInterestModel.BIR) = _getSIRandBIRonBlock(
            _userInterestModel.depositTotalAmount,
            _userInterestModel.borrowTotalAmount
        );

        ///// cal for deposit
        _userInterestModel.globalDepositEXR = _getNewDepositGlobalEXR(
            _DepositActionEXR,
            _userInterestModel.SIR,
            _Delta
        );

        (
            _userInterestModel.depositNegativeFlag,
            _userInterestModel.deltaDepositAmount
        ) = _getNewDeltaRate(
            _userInterestModel.userDepositAmount,
            _userInterestModel.userDepositEXR,
            _userInterestModel.globalDepositEXR
        );
        /////

        ///// cal for borrow
        _userInterestModel.globalBorrowEXR = _getNewDepositGlobalEXR(
            _BorrowActionEXR,
            _userInterestModel.BIR,
            _Delta
        );

        (
            _userInterestModel.borrowNegativeFlag,
            _userInterestModel.deltaBorrowAmount
        ) = _getNewDeltaRate(
            _userInterestModel.userBorrowAmount,
            _userInterestModel.userBorrowEXR,
            _userInterestModel.globalBorrowEXR
        );
        /////

        return (
            _userInterestModel.depositNegativeFlag,
            _userInterestModel.deltaDepositAmount,
            _userInterestModel.globalDepositEXR,
            _userInterestModel.borrowNegativeFlag,
            _userInterestModel.deltaBorrowAmount,
            _userInterestModel.globalBorrowEXR
        );
    }

    function getSIRBIR(uint256 _depositTotalAmount, uint256 _borrowTotalAmount)
        external
        view
        returns (uint256, uint256)
    {
        return _getSIRandBIRonBlock(_depositTotalAmount, _borrowTotalAmount);
    }

    function _getSIRandBIRonBlock(
        uint256 _depositTotalAmount,
        uint256 _borrowTotalAmount
    ) internal view returns (uint256, uint256) {
        uint256 _SIR;
        uint256 _BIR;

        (_SIR, _BIR) = _getSIRandBIR(_depositTotalAmount, _borrowTotalAmount);

        uint256 _finalSIR = _SIR / blocksPerYear;
        uint256 _finalBIR = _BIR / blocksPerYear;

        return (_finalSIR, _finalBIR);
    }

    function _getSIRandBIR(
        uint256 _depositTotalAmount,
        uint256 _borrowTotalAmount
    ) internal view returns (uint256, uint256) {
        uint256 _utilRate = _getUtilizationRate(
            _depositTotalAmount,
            _borrowTotalAmount
        );

        uint256 BIR;
        uint256 _jumpPoint = jumpPoint;

        if (_utilRate < _jumpPoint) {
            BIR = _utilRate.unifiedMul(basicSensitivity).add(minimumRate);
        } else {
            BIR = minimumRate.add(_jumpPoint.unifiedMul(basicSensitivity)).add(
                _utilRate.sub(_jumpPoint).unifiedMul(jumpSensitivity)
            );
        }

        uint256 SIR = _utilRate.unifiedMul(BIR).unifiedMul(spreadRate);
        return (SIR, BIR);
    }

    function _getUtilizationRate(
        uint256 _depositTotalAmount,
        uint256 _borrowTotalAmount
    ) internal pure returns (uint256) {
        if ((_depositTotalAmount == 0) && (_borrowTotalAmount == 0)) {
            return 0;
        }

        return _borrowTotalAmount.unifiedDiv(_depositTotalAmount);
    }

    function _getNewDepositGlobalEXR(
        uint256 _DepositActionEXR,
        uint256 _userInterestModelSIR,
        uint256 _Delta
    ) internal pure returns (uint256) {
        return
            _userInterestModelSIR.mul(_Delta).add(unifiedPoint).unifiedMul(
                _DepositActionEXR
            );
    }

    function _getNewDeltaRate(
        uint256 _userAmount,
        uint256 _userEXR,
        uint256 _globalEXR
    ) internal pure returns (bool, uint256) {
        uint256 _DeltaEXR;
        uint256 _DeltaAmount;
        bool _negativeFlag;

        if (_userAmount != 0) {
            (_negativeFlag, _DeltaEXR) = _getDeltaEXR(_globalEXR, _userEXR);
            _DeltaAmount = _userAmount.unifiedMul(_DeltaEXR);
        }

        return (_negativeFlag, _DeltaAmount);
    }

    function _getDeltaEXR(uint256 _globalEXR, uint256 _userEXR)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 EXR = _globalEXR.unifiedDiv(_userEXR);
        if (EXR >= unifiedPoint) {
            return (false, EXR.sub(unifiedPoint));
        }

        return (true, unifiedPoint.sub(EXR));
    }
}
