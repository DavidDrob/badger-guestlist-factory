pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./TestVipCappedGuestListBbtcUpgradeable.sol";
import "../interfaces/uniswap/IUniswapV2Router02.sol";
import "../interfaces/curve/ICurveSwap.sol";
import "../interfaces/curve/ICurveRegistry.sol";
import "../interfaces/curve/ICurveStableSwap.sol";

contract Factory {
    address immutable guestlistImplementation;

    constructor() public {
        guestlistImplementation = address(
            new TestVipCappedGuestListBbtcUpgradeable()
        );
    }

    // TODO: Add comments
    function createGuestList(
        address _wrapper,
        uint256 _cap,
        uint256 _totalCap,
        bytes32 _merkleRoot,
        address _governance
    ) external returns (address) {
        address clone = Clones.clone(guestlistImplementation);
        TestVipCappedGuestListBbtcUpgradeable(clone).initialize(_wrapper);
        TestVipCappedGuestListBbtcUpgradeable(clone).setUserDepositCap(_cap);
        TestVipCappedGuestListBbtcUpgradeable(clone).setTotalDepositCap(
            _totalCap
        );
        TestVipCappedGuestListBbtcUpgradeable(clone).setGuestRoot(_merkleRoot);
        TestVipCappedGuestListBbtcUpgradeable(clone).transferOwnership(
            _governance
        );
        return clone;
    }

    // TODO: use safemath
    function getAverageTokenPrice(address _token, uint256 _amount)
        external
        view
        returns (uint256)
    {
        uint256[] memory quotes = new uint256[](3);
        uint256 sum;

        uint256 curveQuote = this.getCurveQuote(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            _token,
            _amount
        );
        uint256 uniQuote = this.getUniQuote(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            _token,
            _amount
        );
        uint256 sushiQuote = this.getSushiQuote(
            0xdAC17F958D2ee523a2206206994597C13D831ec7,
            _token,
            _amount
        );

        if (curveQuote > 0) {
            quotes[0] = curveQuote;
        }
        if (uniQuote > 0) {
            quotes[1] = uniQuote;
        }
        if (sushiQuote > 0) {
            quotes[2] = sushiQuote;
        }

        for (uint256 i = 0; i < quotes.length; i++) {
            sum = sum + quotes[i];
        }

        return sum / quotes.length;
    }

    // TODO: Add more price oracles

    function getUniQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amount) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        path[2] = address(tokenOut);

        return
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
                .getAmountsOut(amountIn, path)[2];
    }

    function getSushiQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amount) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        path[2] = address(tokenOut);

        return
            IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F)
                .getAmountsOut(amountIn, path)[2];
    }

    // Works for most tokens
    // TODO: Return `_amount` in correct decimals
    function getCurveQuote(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256) {
        return
            ICurveStableSwap(0x58A3c68e2D3aAf316239c003779F71aCb870Ee47)
                .get_estimated_swap_amount(_from, _to, _amount);
    }

    function getCurveLpVirtualPrice(address _token)
        external
        view
        returns (uint256)
    {
        return
            ICurveRegistry(0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5)
                .get_virtual_price_from_lp_token(_token);
    }

    // Only works for stable coins
    // function getCurveQuote(
    //     address _from,
    //     address _to,
    //     uint256 _amount
    // ) external view returns (address, uint256) {
    //     return
    //         ICurveSwap(0xD1602F68CC7C4c7B59D686243EA35a9C73B0c6a2)
    //             .get_best_rate(_from, _to, _amount);
    // }
}
