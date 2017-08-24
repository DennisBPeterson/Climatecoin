pragma solidity >=0.4.13;

import "./Token.sol";
import "./Owned.sol";

contract Climatecoin is Owned {
    uint startTime;
    Token tok;
    uint BLOCKREWARD = 10**12; //10000 and 8 decimals (e.g.)
    
    function Climatecoin() {
        startTime = block.timestamp; 
        owner = msg.sender;
        tok = new Token();
    }

    function currEpoch() internal returns (uint epoch) {
        epoch = (block.timestamp - startTime) / 1 weeks;
    }

    //******************************
    //GOVERNMENTS
    //******************************

    struct Gov {
        string name;
        bool active;
        uint ethValueBurned;
        uint tokensBurned;
        mapping (address => bool) approved; 
        //TODO: should approved include an exchange rate of tonnage per coin?
        //or maybe tonnage per unit of national currency
        //maybe should only be logged
    }

    mapping (uint => Gov) govs;
    mapping (address => uint) govadmins;
    uint nextGovid = 1;

    function govChangeApproval(address absorber, bool isApproved) {
        uint govid = govadmins[msg.sender];
        require(govid > 0);
        govs[govid].approved[absorber] = isApproved;
    }

    //TODO: allow changing admin

    //TODO: replace owner with governing contract
    function addGov(address admin, string name) onlyOwner {
        govadmins[admin] = nextGovid;
        govs[nextGovid].name = name;
        nextGovid += 1;
    }

    function removeGov(uint govid) onlyOwner {
        govs[govid].active = false;
    }

    //******************************
    //USERS
    //******************************

    //may want to let users add a default govid
    //so they don't accidentally use wrong one
    //we can default this to nonprofit admin
    //but this does add a uint of storage per user!
    //maybe instead put govid in the events
    //and UI can default to govid used last time

    struct User {
        uint lastEpochNumber;
        uint lastEpochContribution;
    }

    //******************************
    //ABSORBERS
    //******************************

    //TODO: change "absorbers" to "mitigators"

    //0x0 is the general allocation
    //all other addresses are absorber addresses

    struct Absorber {
        mapping (address => User) users;
    }

    mapping (address => Absorber) absorbers;

    //******************************
    //EPOCHS
    //******************************

    struct AbsorberEpoch {
        uint totalEthContributed;
        uint availableTokens; 
    }

    struct Epoch {
        mapping (address => AbsorberEpoch) absorbers; 
    }

    mapping (uint => Epoch) epochs;

    //check whether burn or general is cheaper
    function burnIsCheapest(address absorber) private returns (bool) {
        uint tokensForGeneral = BLOCKREWARD / epochs[currEpoch()].absorbers[0x0].totalEthContributed;
        AbsorberEpoch ae = epochs[currEpoch()].absorbers[absorber];
        uint tokensForBurn = ae.availableTokens / ae.totalEthContributed;
        return tokensForBurn > tokensForGeneral;
    }

    function contribute(uint govid, address absorber, uint amount) {
        require(govs[govid].active);
        require(govs[govid].approved[absorber]);
        address applyTo; //defaults to 0x0 which is general fund
        
        //save useburn because we use it several places
        //and we need to make sure it's consistent
        bool useburn = burnIsCheapest(absorber);
        if (useburn) {
            applyTo = absorber;
        }

        epochs[currEpoch()].absorbers[applyTo].totalEthContributed += amount;

        User user = absorbers[absorber].users[msg.sender];

        //if we're in a new epoch, mint for the last epoch
        if (user.lastEpochNumber < currEpoch()) {
            mint(absorber, useburn);        
        }

        //now record the contribution for our current epoch
        user.lastEpochNumber == currEpoch();
        user.lastEpochContribution += amount; //TODO: make sure by-ref works

        //send our new eth to the absorber
        //this must go last
        absorber.transfer(amount);
    }

    function burn(uint govid, address absorber, uint amount) {
        require(govs[govid].active);
        require(govs[govid].approved[absorber]);
        epochs[currEpoch() + 1].absorbers[absorber].availableTokens += amount;

        if (currEpoch() > 0) {
            govs[govid].tokensBurned += amount;
            govs[govid].ethValueBurned += amount * tokenPrice(currEpoch() - 1);
        }

        tok.burn(msg.sender, amount);
        //Burn(govid, absorber, amount);
    }

    function tokenPrice(uint epochnum) returns (uint) {
        AbsorberEpoch ae = epochs[epochnum].absorbers[0x0];
        return ae.totalEthContributed / BLOCKREWARD;
    }

    function mint(address absorber, bool useburn) private {
        User user = absorbers[absorber].users[msg.sender];
        AbsorberEpoch ae = epochs[user.lastEpochNumber].absorbers[absorber];

        //award is absorberEpoch reward divided by user's portion of contributions
        uint tokensAvailable;
        if (useburn) {
            tokensAvailable = ae.availableTokens;
        } else {
            tokensAvailable = BLOCKREWARD;
        }

        uint award = (tokensAvailable * user.lastEpochContribution) / ae.totalEthContributed;

        tok.mint(msg.sender, award);
    }
}

