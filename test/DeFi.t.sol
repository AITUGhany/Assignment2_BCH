pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "../src/LendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10**18);
    }
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract DeFiAdvancedTest is Test {
    AMM public amm;
    LendingPool public lending;
    MockToken public tokenA;
    MockToken public tokenB;

    function setUp() public {
        tokenA = new MockToken("Token A", "TKNA");
        tokenB = new MockToken("Token B", "TKNB");
        amm = new AMM(address(tokenA), address(tokenB));
        lending = new LendingPool(address(tokenA));
        
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        tokenA.approve(address(lending), type(uint256).max);
    }

    function testFuzz_Swap(uint256 amountIn) public {
        amm.addLiquidity(10000 * 10**18, 10000 * 10**18);
        
        // Исправление: Игнорируем "пыль", чтобы избежать округления до нуля при делении
        vm.assume(amountIn > 10000 && amountIn < 1000 * 10**18);
        
        uint256 balBefore = tokenB.balanceOf(address(this));
        amm.swap(address(tokenA), amountIn, 0);
        assertTrue(tokenB.balanceOf(address(this)) > balBefore);
    }

    function test_Invariant_K_Value() public {
        amm.addLiquidity(1000 * 10**18, 1000 * 10**18);
        uint256 kBefore = amm.reserve0() * amm.reserve1();
        
        amm.swap(address(tokenA), 50 * 10**18, 0);
        uint256 kAfter = amm.reserve0() * amm.reserve1();
        
        assertTrue(kAfter >= kBefore, "Invariant K decreased!");
    }

    function test_Lending_InterestAccrual() public {
        lending.deposit(1000 * 10**18);
        lending.borrow(100 * 10**18);
        
        uint256 debtBefore = lending.borrowed(address(this));
        vm.warp(block.timestamp + 365 days);
        lending.deposit(1); 
        
        uint256 debtAfter = lending.borrowed(address(this));
        assertTrue(debtAfter > debtBefore, "Interest was not accrued");
    }

    function test_Fork_USDC_Supply() public {
        // Исправление: Убрали uint256 forkId =, чтобы не было предупреждения Unused variable
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/442nCiA8MwyH1zdPNVHxr");
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        assertTrue(IERC20(usdc).totalSupply() > 0);
    }
}