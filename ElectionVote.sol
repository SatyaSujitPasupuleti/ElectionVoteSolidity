pragma solidity ^0.4.20;
contract Election{
    bytes32 choice1="Hillary";
    bytes32 choice2="Donald";
    uint public votesForChoice1;
    uint public votesForChoice2;
    uint public commitPhaseEndTime;
    uint public revealPhaseEndTime;
    uint public numberOfVotesCast=0;

    bytes32[] public voteCommits;
    mapping(bytes32=>string)voteStatuses;
    mapping(bytes32=>address) addresses;
    event logString(string);
    event newVoteCommit(string, bytes32);
    event voteWinner(string, bytes32);
    //some issues with "now" theoretically miners could make election go on forever"
    constructor(uint _commitPhaseLengthInSeconds){
        require(_commitPhaseLengthInSeconds>=20);
        commitPhaseEndTime = now + _commitPhaseLengthInSeconds * 1 seconds;
        revealPhaseEndTime = commitPhaseEndTime*1 seconds + 300 seconds;

        

    }
    function  commitVote(bytes32 _voteCommit)public {
        require(now < commitPhaseEndTime);
        // Check if this commit has been used before
        bytes memory bytesVoteCommit = bytes(voteStatuses[_voteCommit]);
        require (bytesVoteCommit.length == 0);
        require(addresses[_voteCommit]!=msg.sender);
        // We are still in the committing period & the commit is new so add it
        voteCommits.push(_voteCommit);
        voteStatuses[_voteCommit] = "Committed";
        numberOfVotesCast ++;
        addresses[_voteCommit] = msg.sender;
        emit newVoteCommit("Vote committed with the following hash:", _voteCommit);


    }
    function revealVote(string _vote,bytes32 _voteCommit) public {
         require(now >= commitPhaseEndTime); // Only reveal votes after committing period is over
         
         if(now > revealPhaseEndTime){
             emit logString("TIMEOUT NOT ALL VOTES REVEALED");
             
         }
        // FIRST: Verify the vote & commit is valid
        bytes memory bytesVoteStatus = bytes(voteStatuses[_voteCommit]);
        if (bytesVoteStatus.length == 0) {
            emit logString('A vote with this voteCommit was not cast');
        } else if (bytesVoteStatus[0] != 'C') {
            emit logString('This vote was already cast');
            return;
        }
        
        if (_voteCommit != keccak256(_vote)) {
            emit logString('Vote hash does not match vote commit');
            return;
        }
        //abi.encodePacked
        // NEXT: Count the vote!
        bytes memory bytesVote = bytes(_vote);
        if (bytesVote[0] == '1') {
            votesForChoice1 = votesForChoice1 + 1;
            emit logString('Vote for choice 1 counted.');
        } else if (bytesVote[0] == '2') {
            votesForChoice2 = votesForChoice2 + 1;
            emit logString('Vote for choice 2 counted.');
        } else {
            emit logString('Vote could not be read! Votes must start with the ASCII character `1` or `2`');
        }
        voteStatuses[_voteCommit] = "Revealed";

    }
    function getWinner()  public returns(bytes32){
        // Only get winner after all vote commits are in
        require(now >= commitPhaseEndTime);
        require(now >= revealPhaseEndTime);
        // Make sure all the votes have been counted
        require(votesForChoice1+votesForChoice2== voteCommits.length);
       
        
        if (votesForChoice1 > votesForChoice2) {
           emit voteWinner("And the winner of the vote is:", choice1);
            return choice1;
        } else if (votesForChoice2 > votesForChoice1) {
            emit voteWinner("And the winner of the vote is:", choice2);
            return choice2;
        } else if (votesForChoice1 == votesForChoice2) {
           emit voteWinner("The vote ended in a tie!", "");
            return "It was a tie!";
        }
    }
}





