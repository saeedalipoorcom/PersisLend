//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Proxy/tokenProxy.sol";

contract Master {
    tokenProxy tokenProxyContract;

    function setTokenProxyContract(address _tokenProxyContract)
        external
        returns (bool)
    {
        tokenProxyContract = tokenProxy(_tokenProxyContract);
        return true;
    }

    function getAnswer(address payable _userAddress, uint256 _amount)
        external
        returns (bool)
    {}
}
