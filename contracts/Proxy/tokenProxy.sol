//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Handler/Data/HandlerDataStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract tokenProxy {
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

    address marketHandler;

    constructor(
        address _marketHandler,
        address _DataStorageForHandler,
        address _DAIErc20
    ) {
        Owner = payable(msg.sender);
        marketHandler = _marketHandler;
        DataStorageForHandler = HandlerDataStorage(_DataStorageForHandler);
        DAIErc20 = IERC20(_DAIErc20);
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
}
