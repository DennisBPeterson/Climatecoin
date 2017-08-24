pragma solidity >= 0.4.13;

import "./Owned.sol";

contract Token is Owned {
    uint public totalSupply;
    mapping (address => uint) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address to, uint value) returns (bool) {
        require(balanceOf[msg.sender] < value);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        Transfer(msg.sender, to, value);
    }

    function mint(address to, uint amount) onlyOwner {
        totalSupply += amount;
        balanceOf[to] += amount;
        Transfer(0x0, to, amount);
    }

    function burn(address by, uint amount) onlyOwner {
        require(totalSupply >= amount);
        require(balanceOf[by] >= amount);

        totalSupply -= amount;
        balanceOf[by] -= amount;
        Transfer(by, 0x0, amount);
    }
}

