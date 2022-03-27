pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./TestVipCappedGuestListBbtcUpgradeable.sol";
import "../interfaces/badger/IVault.sol";
import "../interfaces/uniswap/IUniswapV2Router01.sol";
import "../interfaces/curve/ICurveRegistry.sol";
import "../interfaces/curve/ICurveStableSwap.sol";
import "../interfaces/curve/ICurveTriCrypto.sol";
import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../interfaces/uniswap/IUniswapV2Factory.sol";
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

        uint256 userCap = this.getCap(_capUsd, _wrapper);
        uint256 totalCap = this.getCap(_totalCapUsd, _wrapper);

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

    function getCap(uint256 _capUsd, address _wrapper)
        external
        view
        returns (uint256)
    {
        address want = address(this.getVaultTokenAddress(_wrapper));
        uint256 cap;

        try this.getCurveTriCryptoLPQuote(want) returns (uint256 value) {
            if (value > 0) {
                cap = (_capUsd * (10**IERC20(STABLECOIN).decimals()) * (10**18))
                    .div(value);
                return cap;
            }
        } catch (bytes memory) {}

        try this.getLPQuote(want) returns (uint256 value) {
            if (value > 0) {
                cap = (
                    (_capUsd * (10**IERC20(STABLECOIN).decimals()) * (10**18))
                ).div(this.getLPQuote(want));
            }
        } catch (bytes memory) {
            cap = this.getAverageTokenPrice(STABLECOIN, want, _capUsd);
        }

        if (cap == 0) {
            cap = type(uint256).max;
        }
        return cap;
    }

    function getVaultTokenAddress(address _vault)
        external
        view
        returns (IERC20Upgradeable)
    {
        return IVault(_vault).token();
    }

    function getAverageTokenPrice(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint256) {
        uint256[] memory quotes = new uint256[](3);
        uint256 amount = _amount * (10**IERC20(_from).decimals());

        try this.getCurveQuote(_from, _to, amount) returns (
            uint256 curveAmount
        ) {
            if (curveAmount > 0) {
                quotes[0] = curveAmount;
            }
        } catch (bytes memory) {}

        try this.getUniQuote(_from, _to, amount) returns (uint256 uniAmount) {
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

        if (validQuotes == 0) {
            return 0;
        }

        return sum / validQuotes;
    }

    // TODO: Add more price oracles

    function getUniQuote(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amount) {
        uint256 amountOut;

        if (
            address(tokenIn) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 ||
            address(tokenOut) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        ) {
            address[] memory path = new address[](2);
            path[0] = address(tokenIn);
            path[1] = address(tokenOut);
            return UNI_ROUTER.getAmountsOut(amountIn, path)[1];
        } else {
            address[] memory path = new address[](3);
            path[0] = address(tokenIn);
            path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
            path[2] = address(tokenOut);
            amountOut = UNI_ROUTER.getAmountsOut(amountIn, path)[2];
        }

        // Check if amountOut is larger then the reserve in pool
        // Returns 0 if there's too little liquidity in pool
        address pair = IUniswapV2Factory(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        ).getPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, tokenOut);
        (uint256 r1, , ) = IUniswapV2Pair(pair).getReserves();

        if (
            (r1 * 1200000000000000000) / (10**18) >= amountOut &&
            amountOut >= (r1 * 800000000000000000) / (10**18)
        ) {
            amountOut = 0;
        }
        return amountOut;
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
        uint256 amountOut;

        if (
            address(tokenIn) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 ||
            address(tokenOut) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        ) {
            address[] memory path = new address[](2);
            path[0] = address(tokenIn);
            path[1] = address(tokenOut);
            return SUSHI_ROUTER.getAmountsOut(amountIn, path)[1];
        } else {
            address[] memory path = new address[](3);
            path[0] = address(tokenIn);
            path[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
            path[2] = address(tokenOut);

            amountOut = SUSHI_ROUTER.getAmountsOut(amountIn, path)[2];
        }

        // Check if amountOut is larger then the reserve in pool
        // Returns 0 if there's too little liquidity in pool
        address pair = IUniswapV2Factory(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        ).getPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, tokenOut);
        (uint256 r1, , ) = IUniswapV2Pair(pair).getReserves();

        if (
            (r1 * 1200000000000000000) / (10**18) >= amountOut &&
            amountOut >= (r1 * 800000000000000000) / (10**18)
        ) {
            amountOut = 0;
        }
        return amountOut;
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

        // naive way
        uint256 lpPriceNaive = 2 * (((r0 * p0) + (r1 * p1)) / totalSupply);

        // TODO: alpha finance way
        // uint256 k = (this.sqrt(r0 * r1)) / totalSupply;
        // uint256 lpPriceAlpha = 2 * k * this.sqrt(p0 * p1);

        return lpPriceNaive;
    }

    function getCurveTriCryptoLPQuote(address _lp)
        external
        view
        returns (uint256)
    {
        address pool = ICurveRegistry(
            0x8F942C20D02bEfc377D41445793068908E2250D0
        ).get_pool_from_lp_token(_lp);

        if (pool == address(0)) {
            pool = CURVE_REGISTRY.get_pool_from_lp_token(_lp);
        }

        ICurveTriCrypto poolContract = ICurveTriCrypto(pool);

        address token0 = poolContract.coins(0);
        address token1 = poolContract.coins(1);
        address token2 = poolContract.coins(2);

        uint256 p0 = this.getAverageTokenPrice(token0, STABLECOIN, 1);
        uint256 p1 = this.getAverageTokenPrice(token1, STABLECOIN, 1);
        uint256 p2 = this.getAverageTokenPrice(token2, STABLECOIN, 1);
        uint256 v_lp = poolContract.get_virtual_price();

        uint256 price = this.cubicRoot(p0 * p1 * p2);
        uint256 finalPrice = (price * v_lp * 3) / (10**18);

        return finalPrice;
    }

    function getCurvePoolFromLp(address _lp) external view returns (address) {
        address pool = ICurveRegistry(
            0x8F942C20D02bEfc377D41445793068908E2250D0
        ).get_pool_from_lp_token(_lp);

        if (pool == address(0)) {
            pool = ICurveRegistry(0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5)
                .get_pool_from_lp_token(_lp);
        }
        return pool;
    }

    // cubic root
    // https://etherscan.io/address/0xE8b2989276E2Ca8FDEA2268E3551b2b4B2418950#readContract
    function cubicRoot(uint256 y) external pure returns (uint256 z) {
        if (y > 7) {
            z = y;
            uint256 x = y / 3 + 1;
            while (x < z) {
                z = x;
                x = (y / (x * x) + (2 * x)) / 3;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function sqrt(uint256 y) external pure returns (uint256 z) {
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
