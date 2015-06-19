contract Climatecoin {
    address admin;
    address offsetterAdmin;
    address emissionAdmin;

    struct user {
	uint balance;
	uint tonnesContributed; //lifetime total of actual tonnes offset
    }

    mapping (address => user) users;

    //approved offsetters, each with a price per tonne
    mapping (address => uint) offsetters; 

    uint totalEmissions = 0;
    uint totalOffset = 0;

    uint coinStartTime;
    uint emissionStartTime;
    uint emissionUpdateTime;

    event Send(address from, address to, uint value);
    event Mint(address from, address to, uint tonnesCarbon, uint mintedCoins, uint ether);

    //We start with all admins set to the contract creator
    //Emission start time is a year before contract start
    //and we hand-code the global carbon emissions in that year
    function Climatecoin() {
	admin = msg.sender;
	offsetterAdmin = msg.sender;
	emissionAdmin = msg.sender;
	coinStartTime = now;
	emissionUpdateTime = now;
	emissionStartTime = now - 1 year;
	totalTonnesCarbonEmitted = 3 * 10^10; //one year emission at contract start
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
    function setOffsetter(address offsetter, uint pricePerTonne) {
	if (msg.sender == offsetterAdmin || msg.sender == offsetter) {
	    if (pricePerTonner > 0) {
		offsetters[offsetter] = pricePerTonne;
	    }
	}
    }
    function removeOffsetter(address offsetter) {
	if (msg.sender == offsetterAdmin) {
	    if (pricePerTonner > 0) {
		offsetters[offsetter] = 0;
	    }
	}
    }

    //Every now and then, update the global carbon emissions since last update
    //This doesn't have to be on any particular schedule
    function addEmissions(uint newEmissions, uint asOfBlock) {
	if (msg.sender == emissionAdmin) {
	    totalEmissions += newEmissions;
	    lastEmissionUpdate = asOfBlock;
	}
    }

    //if we have one offset tonne per 100 emitted tonnes,
    //then one offset tonne gives 100 coins
    //(that's one coin is one tonne, you might want smaller like wei)
    function coinsPerTonneOffset() returns (uint coinsPerTonne) {
	uint emissionsPerBlock = totalEmissions / (emissionUpdate - emissionStart);
	uint offsetPerBlock = totalOffsets / (now - coinstart);
	return emissionsPerBlock / offsetPerBlock;
    }

    //price per tonne is the wei neeeded to offset one tonne carbon
    //start simplified: award one carboncoin for that
    //and let user specify recipient
    //a separate helper contract can select an offsetter automatically
    function mint(address offsetter) returns (uint coins) {
	uint price = offsetters[offsetter];
	uint offset = (transaction.value / price);
	totalOffset += offset;
	uint coins = offset * coinsPerTonneOffset();
	users[msg.sender].balance += coins;
	users[msg.sender].tonnesContributed += offset;
	send(offsetter, transaction.value); 

	Mint(msg.sender, offsetter, offset, coins, amount);
	return coins;
    }
    function tonnesContributed(address addr) constant returns (uint tonnesContributed) {
        return users.[addr].tonnesContributed;
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
