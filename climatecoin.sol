//One carboncoin is awarded for one 
contract Climatecoin {
    address admin;
    address offsetterAdmin;
    address emissionAdmin;
    address ledger;

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

    //just to make up for lack of foreach 
    //We only need this so we can migrate ledgers
    mapping (uint => address) userids;
    uint nextUserId = 0;

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
    function Climatecoin(uint _emissionStartTime, uint _tonnesEmitted, address _ledger) {
	admin = msg.sender;
	offsetterAdmin = msg.sender;
	emissionAdmin = msg.sender;
	coinStartTime = now;
	emissionUpdateTime = now;
	emissionStartTime = _emissionStartTime; //one year prior
	totalEmissions = _tonnesEmitted; //one year's emissions
	ledger = _ledger;
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

    function changeLedger(address newLedger) {
	if (msg.sender == admin) {
	    //loop through all users and mint them equal coins on new ledger
	    //to do this we need an array, foreach, 
	    //or mapping of counter userids to addresses
	    //then it's newledger.mint(userAddress, coinBalance, totalTonnes)

	    ledger = newLedger;
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
	if (msg.value == 0) return;

	uint price = offsetters[offsetter].price;
	uint offset = (msg.value / price);
	totalOffset += offset;
	coins = offset * coinsPerTonneOffset();

	//just so we can iterate all users when migrating ledger 
	user u = users[msg.sender];
	if (u.tonnesContributed == 0) { userids[nextUserId++] = msg.sender; }

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
    }
    function queryBalance(address addr) constant returns (uint balance) {
        return users[addr].balance;
    }
}

