// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

interface ICurveRegistry {
    function get_virtual_price_from_lp_token(address _token)
        external
        view
        returns (uint256);

    function get_rates(address _pool)
        external
        view
        returns (uint256[] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[] memory);

    function get_coins(address _pool) external view returns (address[] memory MAX_COINS);

    function get_pool_from_lp_token(address _lp)
        external
        view
        returns (address);

    function get_lp_token(address _pool) external view returns (address);
}
