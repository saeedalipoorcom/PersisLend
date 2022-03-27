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
        DataStorageForHandler.addDepositAmount(_userAddress, _amountToDeposit);
        _transferFrom(_userAddress, _amountToDeposit);
        return true;
    }

    function _transferFrom(address payable userAddr, uint256 _amountToDeposit)
        internal
        returns (bool)
    {
        DAIErc20.transferFrom(userAddr, address(this), _amountToDeposit);

        return true;
    }
}
