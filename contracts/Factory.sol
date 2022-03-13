pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./TestVipCappedGuestListBbtcUpgradeable.sol";
import "../interfaces/uniswap/IUniswapV2Router02.sol";
import "../interfaces/curve/ICurveSwap.sol";

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

    function getUniQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);

        return
            IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
                .getAmountsOut(amountIn, path);
    }

    function getSushiQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);

        return
            IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F)
                .getAmountsOut(amountIn, path);
    }

    function getCurveQuote(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (address, uint256) {
        return
            ICurveSwap(0xD1602F68CC7C4c7B59D686243EA35a9C73B0c6a2)
                .get_best_rate(_from, _to, _amount);
        // Always returns ("0x0000000000000000000000000000000000000000", 0)
        // TODO: try `StableSwap.get_swap_from_synth_amount` and `get_dy`
        // https://curve.readthedocs.io/exchange-cross-asset-swaps.html?highlight=swap#StableSwap.get_estimated_swap_amount
        // https://curve.readthedocs.io/factory-pools.html#StableSwap.get_dy
        // https://curve.readthedocs.io/registry-exchanges.html#Swaps.get_best_rate https://github.com/curvefi/curve-pool-registry/blob/master/contracts/Swaps.vy#L568
    }
}
