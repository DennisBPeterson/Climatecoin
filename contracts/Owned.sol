pragma solidity >= 0.4.13;

contract Owned {
    address owner;
    function Owned() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
}

