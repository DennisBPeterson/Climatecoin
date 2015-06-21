contract Climatevotes {
    address climatecoin;
    address admin;
    uint electionLength;
    uint quorum; 

    struct ballot {
	uint deadline;
	bool tallied;
	uint price;
	address priceAdmin;
	//votes: 0 not voted, 1 in favor, 2 against
	mapping (uint => uint) votes;
	mapping (address => uint) voters;
	uint nextVoterId;
    }
    //address is the offsetter 
    mapping (address => ballot) ballots;



    function Climatevotes(address _coin, address _admin, uint _quorum, uint _electionLength) {
	climatecoin = _coin;
	admin = _admin;
	quorum = _quorum;
	electionLength = _electionLength;
    }

    function setQuorum(uint _quorum) {
	if (msg.sender == admin) {
	    quorum = _quorum;
	}
    }
    function setAdmin(address _admin) {
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
	if (ballots[offsetter].deadline == 0) {
	    ballot b;
	    b.deadline = block.number + electionLength;
	    b.tallied = false;
	    ballots[offsetter].deadline = block.number + electionLength;
	}
    }

    //mapping (uint => uint) votes;
    //mapping (uint => address) voters;
    //uint nextVoterId = 0;
    function vote(address offsetter, bool approves) {
	ballot b = ballots[offsetter];
	if (b.deadline > block.number) {
	    //need to trap missing offsetter
	    uint voterid =  b.voters[msg.sender];
	    if (voterid == 0) {
		voterid = b.nextVoterId;
		b.nextVoterId += 1;
		b.voters[msg.sender] = voterid;
	    }
	    if (approves) {
		b.votes[voterid] = 1;
	    } else {
		b.votes[voterid] = 1;
	    }
	}
    }

    function tally(address offsetter) {
	ballot b = ballots[offsetter];
	if (b.tallied) return;  //how do null check?
	if (b.deadline > 0 && b.deadline < block.number) {
	    b.tallied = true;
	    uint yay = 0;
	    uint nay = 0;

	    for (uint i = 0; i < b.nextVoterId; i++) {
		address voter = b.voters[i];
		uint weight = climatecoin.tonnesContributed(voter);
		uint vote = b.votes[voter];
		if (vote == 1) yay += weight;
		if (vote == 2) nay += weight;
	    }

	    if (yay + nay >= quorum && yay > nay) {
		climatecoin.addOffsetter(
		    offsetter, 
		    b.price, 
		    b.priceAdmin);
	    }
	}
    }

}

