// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface ICurveTriCrypto {
    function get_virtual_price() external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function balances(uint256 arg0) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function price_oracle(uint256 k) external view returns (uint256);
}
