//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./OracleInterface.sol";

contract oracleProxy {
    address payable owner;

    mapping(uint256 => Oracle) oracle;

    struct Oracle {
        OracleInterface feed;
    }

    uint256 constant unifiedPoint = 10**18;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address daiOracle, address ethOracle) {
        owner = payable(msg.sender);
        _setOracleFeed(1, daiOracle);
        _setOracleFeed(2, ethOracle);
    }

    /**
     * @dev Replace the owner of the handler
     * @param _owner the address of the owner to be replaced
     * @return true (TODO: validate results)
     */
    function ownershipTransfer(address payable _owner)
        public
        onlyOwner
        returns (bool)
    {
        owner = _owner;
        return true;
    }

    function setOracleFeed(uint256 tokenID, address feedAddr)
        external
        onlyOwner
        returns (bool)
    {
        return _setOracleFeed(tokenID, feedAddr);
    }

    function _setOracleFeed(uint256 tokenID, address feedAddr)
        internal
        returns (bool)
    {
        Oracle memory _oracle;
        _oracle.feed = OracleInterface(feedAddr);

        oracle[tokenID] = _oracle;
        return true;
    }

    /**
     * @dev The price of the token is obtained through the price feed contract.
     * @param tokenID The ID of the token that will take the price.
     * @return The token price of a uniform unit.
     */
    function getTokenPrice(uint256 tokenID) external view returns (uint256) {
        Oracle memory _oracle = oracle[tokenID];
        uint256 underlyingPrice = _oracle.feed.latestAnswer();

        require(underlyingPrice != 0);
        return underlyingPrice;
    }

    /**
     * @dev Get owner's address in manager contract
     * @return The address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @dev Unify the decimal value of the token price returned by price feed oracle.
     * @param price token price without unified of decimal
     * @param feedUnderlyingPoint Decimal of the token
     * @return The price of tokens with unified decimal
     */
    function _convertPriceToUnified(uint256 price, uint256 feedUnderlyingPoint)
        internal
        pure
        returns (uint256)
    {
        return div(mul(price, unifiedPoint), feedUnderlyingPoint);
    }

    /* **************** safeMath **************** */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _mul(a, b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "div by zero");
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

    function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(_mul(a, b), unifiedPoint, "unified mul by zero");
    }
}
