contract Climatevotes {
    address climatecoin;
    uint electionLength;
    uint quorum; 

    struct ballot {
	uint deadline;
	bool tallied;
	uint price;
	address priceAdmin;
	//votes: 0 not voted, 1 in favor, 2 against
	//address is a holder of climatecoins
	mapping (address => uint) votes;
    }
    //address is the offsetter 
    mapping (address => ballot) ballots;

    function Climatevotes(address _coin, address _admin, uint _quorum, uint _electionLength) {
	climatecoin = _coin;
	admin = _admin;
	electionLength = _electionLength;
	quorum = _quorum;
    }

    function setQuorum(uint _quorum) {
	if (msg.sender == admin) {
	    quorum = _quorum
	}
    }
    function setAdmin(uint _admin) {
	if (msg.sender == admin) {
	    admin = _admin;
	}
    }
    function setElectionLength(uint _electionLength) {
	if (msg.sender == admin) {
	    electionLength = _electionLength;
	}
    }

    function propose(address offsetter) {
	if (ballots[address].deadline == 0) {
	    ballot b;
	    b.deadline = block.number + electionPeriodInBlocks;
	    b.tallied = false;
	    ballots[offsetter].deadline = block.number + electionLength;
	}
    }

    function vote(address offsetter, address voter, bool approves) {
	if (ballots[offsetter].deadline > block.number) {
	    ballots[offsetter].votes[msg.sender] = approves;
	}
    }

    function tally(address offsetter) {
	if (ballots[offsetter].tallied) return;
	ballot b = ballots[offsetter];
	if (b.deadline > 0 && b.deadline < block.number) {
	    ballots[offsetter].tallied = true;
	    uint yay = 0;
	    uint nay = 0;

	    //does solidity have foreach?
	    for (address a in ballots.keys) {
		//go to climatecoin to get weighting for voter
		uint vote = ballots[address];
		if (vote == 1) yay += 1;
		if (vote == 2) nay += 1;
	    }

	    if (yay + nay >= quorum && yay > nay) {
		climatecoin.addOffsetter(
		    offsetter, 
		    ballots[offsetter].price, 
		    ballots.offsetter].priceAdmin);
	    }
	}
    }

}

