// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface ICurveRegistry {
    function get_virtual_price_from_lp_token(
        address _token
    ) external view returns (uint256);
}
