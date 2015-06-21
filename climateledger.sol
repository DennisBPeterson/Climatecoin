contract ClimateLedger {
    address controller;

    struct user {
	uint balance;
	uint tonnesContributed; //lifetime total of actual tonnes offset
    }

    mapping (address => user) users;
    
    event Send(address from, address to, uint value);

    function ClimatecoinLedger(address _controller) {controller = _controller;}

    //both for routine minting and transition to new ledger
    function mint(address user, uint coins, uint tonnes) {
	if (msg.sender == controller) {
	    users[user].balance += balance;
	    users[user].tonnesContributed += tonnes;
	}
    }

    function send(address sender, address receiver, uint amount) {
	if (msg.sender == controller) {
	    if (users[sender].balance < amount) return;
	    users[msg.sender].balance -= amount;
	    users[receiver].balance += amount;
	    Send(msg.sender, receiver, amount);
	}
    }

    function queryBalance(address addr) constant returns (uint balance) {
        return users[addr].balance;
    }
}

