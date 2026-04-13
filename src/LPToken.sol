pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LPToken is ERC20 {
    address public owner;
    constructor() ERC20("AMM LP Token", "AMMLP") {
        owner = msg.sender;
    }
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "Only AMM can mint");
        _mint(to, amount);
    }
    function burn(address from, uint256 amount) external {
        require(msg.sender == owner, "Only AMM can burn");
        _burn(from, amount);
    }
}
