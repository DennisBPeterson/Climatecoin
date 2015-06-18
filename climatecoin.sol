contract Climatecoin {
    address admin;
    address offsetterAdmin;
    address emissionAdmin;
    mapping (address => uint) balances;
    mapping (address => uint) offsetters;

    uint totalEmissions = 0;
    uint totalOffset = 0;

    uint coinStartTime;
    uint emissionStartTime;
    uint emissionUpdateTime;

    event Send(address from, address to, uint value);

    function Climatecoin() {
	admin = msg.sender;
	offsetterAdmin = msg.sender;
	emissionAdmin = msg.sender;
	coinStartTime = now;
	emissionUpdateTime = now;
	emissionStartTime = now - (365 * 24 * 3600);
	totalTonnesCarbonEmitted = 3 * 10^10; //one year emission at contract start
    }
    //hopefully we can set admin to a schelling contract later
    //if not then a multi-admin contract
    //don't make a mistake calling this function!
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

    function addEmissions(uint newEmissions, timestamp asOfBlock) {
	if (msg.sender == emissionAdmin) {
	    totalTonnesCarbonEmitted += newEmissions;
	    lastEmissionUpdate = asOfBlock;
	}
    }

    //if we have one offset tonne per 100 emitted tonnes,
    //then one offset tonne gives 100 coins
    //(that's one coin is one tonne, you might want smaller like wei)
    function coinsPerTonneOffset() {
	uint emissionsPerBlock = totalEmissions / (emissionUpdate - emissionStart);
	uint offsetPerBlock = totalOffsets / (now - coinstart);
	return emissionsPerBlock / offsetPerBlock;
    }

    //price per tonne is the wei neeeded to offset one tonne carbon
    //start simplified: award one carboncoin for that
    //and let user specify recipient
    //a separate helper contract can select an offsetter automatically
    function mint(uint amount, address offsetter) {
	uint price = offsetters[offsetter];
	uint offset = (transaction.value / price);
	uint totalOffset += offset;
	uint coins = offset * coinsPerTonneOffset;
	balances[msg.sender] += coins;
	send(offsetter, amount);
	return coins;
    }

    //the usual currency functions
    function send(address receiver, uint amount) {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        Send(msg.sender, receiver, amount);
    }
    function queryBalance(address addr) constant returns (uint balance) {
        return balances[addr];
    }
}
