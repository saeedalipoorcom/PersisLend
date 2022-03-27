//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Data/HandlerDataStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract marketHandler {
    event Deposit(
        address _depositedFrom,
        uint256 _amountToDeposit,
        uint256 _handlerID
    );
    event OwnershipTransferred(address owner, address newOwner);

    address payable Owner;

    uint256 handlerID = 0;
    string tokenName = "DAI";

    uint256 constant unifiedPoint = 10**18;

    HandlerDataStorage DataStorageForHandler;
    IERC20 DAIErc20;

    modifier OnlyOwner() {
        require(msg.sender == Owner, "OnlyOwner");
        _;
    }

    constructor(address _DataStorageForHandler, address _DAIErc20) {
        Owner = payable(msg.sender);
        DataStorageForHandler = HandlerDataStorage(_DataStorageForHandler);
        DAIErc20 = IERC20(_DAIErc20);
    }

    function setCircuitBreaker(bool _emergency)
        external
        OnlyOwner
        returns (bool)
    {
        DataStorageForHandler.setCircuitBreaker(_emergency);
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

        _checkIfUserIsNew(_userAddress);

        DataStorageForHandler.addDepositAmount(_userAddress, _amountToDeposit);
        DAIErc20.transferFrom(_userAddress, address(this), _amountToDeposit);

        return true;
    }

    function withdraw(uint256 _amountToWithdraw)
        external
        payable
        returns (bool)
    {
        require(msg.value == 0);
        address payable _userAddress = payable(msg.sender);
        DataStorageForHandler.subDepositAmount(_userAddress, _amountToWithdraw);
        DAIErc20.transfer(_userAddress, _amountToWithdraw);
        return true;
    }

    function _checkIfUserIsNew(address payable _userAddress)
        internal
        returns (bool)
    {
        bool isUserNew = DataStorageForHandler.getUserAccessed(_userAddress);

        if (isUserNew) {
            return false;
        }

        DataStorageForHandler.setuserAccesse(_userAddress, true);
        (uint256 globaBEXR, uint256 globalDEXR) = DataStorageForHandler
            .getGlobalEXR();
        DataStorageForHandler.setUserEXR(_userAddress, globalDEXR, globaBEXR);
    }

    function syncAndUpdateBlocks() internal returns (bool) {
        uint256 lastUpdateBlock = DataStorageForHandler.getLastUpdateBlock();
        uint256 currentBlockNumber = block.number;
        uint256 deltaBlock = currentBlockNumber - lastUpdateBlock;

        if (deltaBlock > 0) {
            DataStorageForHandler.setBlocks(currentBlockNumber, deltaBlock);
            DataStorageForHandler.syncEXR();
            return true;
        }

        return false;
    }
}
