pragma solidity ^0.7.0;

contract Test {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct Proposal {
        bytes32 name;
        uint voteCount;
    }

    address public chairperson; 

    mapping(address => Voter) public voters; 
    Proposal[] public proposals; 

    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender; 
        voters[chairperson].weight = 1;

        for(uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    //Chairperson method: gives voter rights to vote
    function givveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote"
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    //continuously iterate and find the correct address to delegate to
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed");
        
        //terminates with the correct "to" address
        while(voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            //finds if theres is a loop in the delegation path
            require(to != msg.sender, "Found loop in delegation.");
        }

        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if(delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }
    
    //give your vote + delegated votes to proposal
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = proposal;

        //safe operation: if fails then the vote will revert all changes
        proposals[proposal].voteCount += sender.weight;
    }

    //Iterates through all the proposals to find the winning proposals
    //In a tie: take the first proposal
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for(uint p = 0; p < proposals.length; p++) {
            if(proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() public view returns (bytes32 winnerName_) {   
        winnerName_ = proposals[winningProposal()].name;
    }
}