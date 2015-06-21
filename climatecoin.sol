contract Climatecoin {
    address admin;
    address offsetterAdmin;
    address emissionAdmin;

    uint totalEmissions = 0;
    uint totalOffset = 0;

    uint coinStartTime;
    uint emissionStartTime;
    uint emissionUpdateTime;

    struct user {
	uint balance;
	uint tonnesContributed; //lifetime total of actual tonnes offset
    }

    mapping (address => user) users;

    //approved offsetters, each with a price per tonne
    struct offsetter {
	uint price;
	address admin;
	bool active;
    }
    mapping (address => offsetter) offsetters; 

    event Mint(address from, address to, uint tonnesCarbon, uint mintedCoins, uint etherAmount);

    //We start with all admins set to the contract creator
    //Emission start time is a year before contract start
    //and we hand-code the global carbon emissions in that year
    function Climatecoin(uint _emissionStartTime, uint _tonnesEmitted) {
	admin = msg.sender;
	offsetterAdmin = msg.sender;
	emissionAdmin = msg.sender;
	coinStartTime = now;
	emissionUpdateTime = now;
	emissionStartTime = _emissionStartTime; //one year prior
	totalEmissions = _tonnesEmitted; //one year's emissions
    }

    //After startup, admin can pass off power to more decentralized entities
    //Those can schelling contracts, voting systems, etc.
    function changeAdmin(address newAdmin) {
	if (msg.sender == admin) {
	    admin = newAdmin;
	}
    }
    function changeOffsetterAdmin(address newAdmin) {
	if (msg.sender == admin) {
	    offsetterAdmin = newAdmin;
	}
    }
    function changeEmissionAdmin(address newAdmin) {
	if (msg.sender == admin) {
	    emissionAdmin = newAdmin;
	}
    }

    //Maintain list of approved offsetters
    //Admin or offsetter can update price of one tonne carbon offset
    function addOffsetter(address offsetter, uint pricePerTonne, address admin) {
	if (msg.sender == offsetterAdmin) {
	    if (pricePerTonne > 0) {
		offsetters[offsetter].price = pricePerTonne;
		offsetters[offsetter].admin = admin;
		offsetters[offsetter].active = true;
	    }
	}
    }
    function removeOffsetter(address offsetter) {
	if (msg.sender == offsetterAdmin) {
	    if (offsetters[offsetter].active) {
		offsetters[offsetter].active = false;
	    }
	}
    }
    function changeOffsetPrice(address offsetter, uint price) {
	if (msg.sender == offsetters[offsetter].admin && offsetters[offsetter].active) {
	    offsetters[offsetter].price = price;
	}
    }
    function changeOffsetPriceAdmin(address offsetter, address admin) {
	if (msg.sender == offsetters[offsetter].admin && offsetters[offsetter].active) {
	    offsetters[offsetter].admin = admin;
	}
    }

    //Every now and then, update the global carbon emissions since last update
    //This doesn't have to be on any particular schedule
    function addEmissions(uint newEmissions, uint updateTime) {
	if (msg.sender == emissionAdmin) {
	    totalEmissions += newEmissions;
	    emissionUpdateTime = updateTime;
	}
    }

    //if we have one offset tonne per 100 emitted tonnes,
    //then one offset tonne gives 100 coins
    //(that's one coin is one tonne, you might want smaller like wei)
    function coinsPerTonneOffset() returns (uint coinsPerTonne) {
	uint emissionsPerSecond = totalEmissions / (emissionUpdateTime - emissionStartTime);
	uint offsetPerSecond = totalOffset / (now - coinStartTime);
	return emissionsPerSecond / offsetPerSecond;
    }

    //price per tonne is the wei neeeded to offset one tonne carbon
    //start simplified: award one carboncoin for that
    //and let user specify recipient
    //a separate helper contract can select an offsetter automatically
    function mint(address offsetter) returns (uint coins) {
	uint price = offsetters[offsetter].price;
	uint offset = (msg.value / price);
	totalOffset += offset;
	coins = offset * coinsPerTonneOffset();
	users[msg.sender].balance += coins;
	users[msg.sender].tonnesContributed += offset;
	send(offsetter, msg.value); 

	Mint(msg.sender, offsetter, offset, coins, msg.value);
	return coins;
    }
    function tonnesContributed(address user) constant returns (uint tonnesContributed) {
        return users[user].tonnesContributed;
    }

    //the usual currency functions
    function send(address receiver, uint amount) {
        if (users[msg.sender].balance < amount) return;
        users[msg.sender].balance -= amount;
        users[receiver].balance += amount;
        Send(msg.sender, receiver, amount);
    }
    function queryBalance(address addr) constant returns (uint balance) {
        return users[addr].balance;
    }
}

contract ClimateCoinLedger {
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
