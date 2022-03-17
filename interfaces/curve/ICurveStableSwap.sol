// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface ICurveStableSwap {
    function get_estimated_swap_amount(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256);
}
