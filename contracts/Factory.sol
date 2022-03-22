pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./TestVipCappedGuestListBbtcUpgradeable.sol";
import "../interfaces/badger/IVault.sol";
import "../interfaces/uniswap/IUniswapV2Router01.sol";
import "../interfaces/curve/ICurveRegistry.sol";
import "../interfaces/curve/ICurveStableSwap.sol";
import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../interfaces/erc20/IERC20.sol";

contract Factory {
    address immutable guestlistImplementation;
    using SafeMath for uint256;
    using SafeMath for uint8;

    address public constant STABLECOIN =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    uint8 public constant STABLECOIN_DECIMALS = 18;

    IUniswapV2Router01 public constant UNI_ROUTER =
        IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router01 public constant SUSHI_ROUTER =
        IUniswapV2Router01(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    ICurveRegistry public constant CURVE_REGISTRY =
        ICurveRegistry(0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5);

    // address[] public uni_routers = [
    //     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
    //     0x58A3c68e2D3aAf316239c003779F71aCb870Ee47
    // ];

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

        // TODO: If no price was found return `type(uint256).max`
        uint256 userCap = this.getAverageTokenPrice(STABLECOIN, want, _capUsd);
        uint256 totalCap = this.getAverageTokenPrice(STABLECOIN, want, _totalCapUsd);

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

    function getAverageTokenPrice(address _from, address _to, uint256 _amount)
        external
        view
        returns (uint256)
    {
        uint256[] memory quotes = new uint256[](3);
        uint256 amount = _amount * (10 ** IERC20(_from).decimals());

        try this.getCurveQuote(_from, _to, amount) returns (
            uint256 curveAmount
        ) {
            if (curveAmount > 0) {
                quotes[0] = curveAmount;
            }
        } catch (bytes memory) {}

        try this.getUniQuote(_from, _to, amount) returns (
            uint256 uniAmount
        ) {
            if (uniAmount > 0) {
                quotes[1] = uniAmount;
            }
        } catch (bytes memory) {}

        try this.getSushiQuote(_from, _to, amount) returns (
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

        // If 0 valid quotes -> call the `getLPQuote` function

        return sum / validQuotes;
    }

    // TODO: Add more price oracles

    function getUniQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amount) {
        if (address(tokenIn) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 || address(tokenOut) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            address[] memory path = new address[](2);
            path[0] = address(tokenIn);
            path[1] = address(tokenOut);
            return UNI_ROUTER.getAmountsOut(amountIn, path)[1];
        }
        else {
            address[] memory path = new address[](3);
            path[0] = address(tokenIn);
            path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
            path[2] = address(tokenOut);
            return UNI_ROUTER.getAmountsOut(amountIn, path)[2];
        }

        // uint256 sum;
        // uint8 validQuotes;
        // for (uint256 i = 0; i < uni_routers.length; i++) {
        //     uint256 amountsOut = IUniswapV2Router01(uni_routers[i])
        //         .getAmountsOut(amountIn, path)[2];
        //     if (amountsOut > 0) {
        //         sum += amountsOut;
        //         validQuotes += 1;
        //     }
        // }

        // return sum / validQuotes;
    }

    function getSushiQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amount) {
        if (address(tokenIn) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 || address(tokenOut) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            address[] memory path = new address[](2);
            path[0] = address(tokenIn);
            path[1] = address(tokenOut);
            return SUSHI_ROUTER.getAmountsOut(amountIn, path)[1];
        }
        else {
            address[] memory path = new address[](3);
            path[0] = address(tokenIn);
            path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
            path[2] = address(tokenOut);

            return SUSHI_ROUTER.getAmountsOut(amountIn, path)[2];
        }


    }

    function getCurveQuote(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256) {
        return
            ICurveStableSwap(0x58A3c68e2D3aAf316239c003779F71aCb870Ee47)
                .get_estimated_swap_amount(_from, _to, _amount);
    }

    function getLPQuote(address pair) external view returns (uint256) {
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 totalSupply = IUniswapV2Pair(pair).totalSupply();
        (uint256 r0, uint256 r1, ) = IUniswapV2Pair(pair).getReserves();

        uint256 p0 = this.getAverageTokenPrice(token0, STABLECOIN, 1);
        uint256 p1 = this.getAverageTokenPrice(token1, STABLECOIN, 1);

        // TODO: Test trycrypto pools
        // Multiply by 3 for tricrypto pools (?)

        // naive option
        uint256 lpPrice = 2 * (((r0 * p0) + (r1 * p1)) / totalSupply);

        // TODO: alpha finance option

        return lpPrice;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
