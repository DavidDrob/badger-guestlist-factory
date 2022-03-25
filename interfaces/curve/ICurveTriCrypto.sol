// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface ICurveTriCrypto {
    function get_virtual_price()
        external
        view
        returns (uint256);

    function coins(uint256 i)
        external
        view
        returns (address);
}
