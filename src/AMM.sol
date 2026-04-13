pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LPToken.sol";

contract AMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    LPToken public immutable lpToken;
    uint256 public reserve0;
    uint256 public reserve1;

    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amount0, uint256 amount1, uint256 shares);
    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        lpToken = new LPToken();
    }

    function getAmountOut(uint256 amountIn, uint256 resIn, uint256 resOut) public pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        return (amountInWithFee * resOut) / ((resIn * 1000) + amountInWithFee);
    }

    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 shares) {
        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        uint256 _totalSupply = lpToken.totalSupply();
        if (_totalSupply == 0) {
            shares = sqrt(amount0 * amount1);
        } else {
            shares = min((amount0 * _totalSupply) / reserve0, (amount1 * _totalSupply) / reserve1);
        }
        require(shares > 0, "Zero shares");

        reserve0 += amount0;
        reserve1 += amount1;
        lpToken.mint(msg.sender, shares);
        emit LiquidityAdded(msg.sender, amount0, amount1, shares);
    }

    function removeLiquidity(uint256 shares) external returns (uint256 amount0, uint256 amount1) {
        uint256 _totalSupply = lpToken.totalSupply();
        amount0 = (shares * reserve0) / _totalSupply;
        amount1 = (shares * reserve1) / _totalSupply;

        lpToken.burn(msg.sender, shares);
        reserve0 -= amount0;
        reserve1 -= amount1;

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
        emit LiquidityRemoved(msg.sender, amount0, amount1, shares);
    }

    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        bool isToken0 = tokenIn == address(token0);
        (uint256 rIn, uint256 rOut) = isToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
        
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        amountOut = getAmountOut(amountIn, rIn, rOut);
        require(amountOut >= minAmountOut, "Slippage too high");

        if (isToken0) {
            reserve0 += amountIn;
            reserve1 -= amountOut;
            token1.transfer(msg.sender, amountOut);
        } else {
            reserve1 += amountIn;
            reserve0 -= amountOut;
            token0.transfer(msg.sender, amountOut);
        }
        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint) {
        return x <= y ? x : y;
    }
}