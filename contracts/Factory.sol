pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./TestVipCappedGuestListBbtcUpgradeable.sol";
import "../interfaces/badger/IVault.sol";
import "../interfaces/uniswap/IUniswapV2Router02.sol";
import "../interfaces/curve/ICurveSwap.sol";
import "../interfaces/curve/ICurveRegistry.sol";
import "../interfaces/curve/ICurveStableSwap.sol";

contract Factory {
    address immutable guestlistImplementation;

    // TODO: Add constant for interfaces
    address public constant STABLECOIN =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint8 public constant STABLECOIN_DECIMALS = 18;

    constructor() public {
        guestlistImplementation = address(
            new TestVipCappedGuestListBbtcUpgradeable()
        );
    }

    // TODO: Add comments
    function createGuestList(
        address _wrapper,
        uint256 _capUsd,
        uint256 _totalCapUsd,
        bytes32 _merkleRoot,
        address _governance
    ) external returns (address) {
        address clone = Clones.clone(guestlistImplementation);

        address want = address(this.getVaultTokenAddress(_wrapper));
        uint256 userCap = this.getAverageTokenPrice(want, _capUsd);
        uint256 totalCap = this.getAverageTokenPrice(want, _totalCapUsd);

        TestVipCappedGuestListBbtcUpgradeable(clone).initialize(_wrapper);
        TestVipCappedGuestListBbtcUpgradeable(clone).setUserDepositCap(userCap);
        TestVipCappedGuestListBbtcUpgradeable(clone).setTotalDepositCap(
            totalCap
        );
        TestVipCappedGuestListBbtcUpgradeable(clone).setGuestRoot(_merkleRoot);
        TestVipCappedGuestListBbtcUpgradeable(clone).transferOwnership(
            _governance
        );
        return clone;
    }

    function getVaultTokenAddress(address _vault)
        external
        view
        returns (IERC20Upgradeable)
    {
        return IVault(_vault).token();
    }

    // TODO: use safemath
    function getAverageTokenPrice(address _token, uint256 _amount)
        external
        view
        returns (uint256)
    {
        uint256[] memory quotes = new uint256[](3);

        try this.getCurveQuote(STABLECOIN, _token, _amount) returns (
            uint256 curveAmount
        ) {
            if (curveAmount > 0) {
                quotes[0] = curveAmount;
            }
        } catch (bytes memory) {}

        try this.getUniQuote(STABLECOIN, _token, _amount) returns (
            uint256 uniAmount
        ) {
            if (uniAmount > 0) {
                quotes[1] = uniAmount;
            }
        } catch (bytes memory) {}

        try this.getSushiQuote(STABLECOIN, _token, _amount) returns (
            uint256 sushiAmount
        ) {
            if (sushiAmount > 0) {
                quotes[2] = sushiAmount;
            }
        } catch (bytes memory) {}

        uint256 sum;
        uint8 validQuotes;
        for (uint256 i = 0; i < quotes.length; i++) {
            if (quotes[i] > 0) {
                validQuotes += 1;
                sum += quotes[i];
            }
        }

        return sum / validQuotes;
    }

    // TODO: Add more price oracles

    function getUniQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amount) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
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
        path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
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
