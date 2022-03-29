// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface ICurvePool {
    function coins(int128 arg0)
        external
        view
        returns (address);

    function balances(int128 arg0) external view returns (uint256);

}
