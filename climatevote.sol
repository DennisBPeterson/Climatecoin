contract Climatevotes {
    address climatecoin;
    address admin;
    uint electionLength;
    uint quorum; 

    struct ballot {
	address voter;
	uint vote; //0 not voted, 1 aye, 2 nay
    }

    struct election {
	uint deadline;
	bool tallied;
	uint price;
	address priceAdmin;
	//votes: 0 not voted, 1 in favor, 2 against
	mapping (uint => vote) votes;
	mapping (address => uint) voters;
	uint nextVoterId;
    }

    //address is the offsetter 
    mapping (address => election) elections;

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
	if (elections[offsetter].deadline == 0) {
	    election e;
	    e.deadline = block.number + electionLength;
	    e.tallied = false;
	    elections[offsetter] = e;
	}
    }

    //mapping (uint => uint) votes;
    //mapping (uint => address) voters;
    //uint nextVoterId = 0;
    function vote(address offsetter, bool approves) {
	election e = elections[offsetter];
	if (e.deadline > block.number) {
	    //need to trap missing offsetter
	    uint voterid =  e.voters[msg.sender];
	    if (voterid == 0) {
		voterid = e.nextVoterId;
		e.nextVoterId += 1;
		e.voters[msg.sender] = voterid;
	    }
	    if (approves) {
		e.votes[voterid].voter = msg.sender;
		e.votes[voterid].vote = 1;
	    } else {
		e.votes[voterid].voter = msg.sender;
		e.votes[voterid].valte = 2;
	    }
	}
    }

    function tally(address offsetter) {
	election e = elections[offsetter];
	if (e.tallied) return;  //how do null check?
	if (e.deadline > 0 && e.deadline < block.number) {
	    e.tallied = true;
	    uint yay = 0;
	    uint nay = 0;

	    for (uint i = 0; i < e.nextVoterId; i++) {
		address voter = e.votes[i].voter;
		uint weight = climatecoin.tonnesContributed(voter);
		uint vote = e.votes[voter].vote;
		if (vote == 1) yay += weight;
		if (vote == 2) nay += weight;
	    }

	    if (yay + nay >= quorum && yay > nay) {
		climatecoin.addOffsetter(
		    offsetter, 
		    e.price, 
		    e.priceAdmin);
	    }
	}
    }

}

