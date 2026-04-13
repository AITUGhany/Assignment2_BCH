pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    IERC20 public collateralToken;
    mapping(address => uint256) public collateral;
    mapping(address => uint256) public borrowed;
    mapping(address => uint256) public lastUpdate;
    
    uint256 public constant LTV_LIMIT = 75;
    uint256 public constant BORROW_RATE_APR = 5;

    constructor(address _token) {
        collateralToken = IERC20(_token);
    }

    function accrueInterest(address user) internal {
        uint256 timeElapsed = block.timestamp - lastUpdate[user];
        if (timeElapsed > 0 && borrowed[user] > 0) {
            uint256 interest = (borrowed[user] * BORROW_RATE_APR * timeElapsed) / (100 * 365 days);
            borrowed[user] += interest;
        }
        lastUpdate[user] = block.timestamp;
    }

    function deposit(uint256 amount) external {
        accrueInterest(msg.sender);
        collateralToken.transferFrom(msg.sender, address(this), amount);
        collateral[msg.sender] += amount;
        lastUpdate[msg.sender] = block.timestamp;
    }

    function borrow(uint256 amount) external {
        accrueInterest(msg.sender);
        uint256 maxBorrow = (collateral[msg.sender] * LTV_LIMIT) / 100;
        require(borrowed[msg.sender] + amount <= maxBorrow, "Exceeds 75% LTV");
        borrowed[msg.sender] += amount;
    }

    function repay(uint256 amount) external {
        accrueInterest(msg.sender);
        require(borrowed[msg.sender] >= amount, "Repaying too much");
        borrowed[msg.sender] -= amount;
    }

    function withdraw(uint256 amount) external {
        accrueInterest(msg.sender);
        require(collateral[msg.sender] >= amount, "Insufficient collateral");
        uint256 remainingCollateral = collateral[msg.sender] - amount;
        uint256 maxBorrow = (remainingCollateral * LTV_LIMIT) / 100;
        require(borrowed[msg.sender] <= maxBorrow, "Health factor too low");
        
        collateral[msg.sender] -= amount;
        collateralToken.transfer(msg.sender, amount);
    }

    function getHealthFactor(address user) public view returns (uint256) {
        if (borrowed[user] == 0) return 100e18;
        return (collateral[user] * LTV_LIMIT * 1e18) / (borrowed[user] * 100);
    }
}