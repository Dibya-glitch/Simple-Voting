// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Simple voting
 * @dev A smart contract for conducting simple and transparent voting
 * @author Simple Voting Team
 */
contract Project {
    
    // State variables
    address public admin;
    uint256 public totalVotes;
    bool public votingOpen;
    
    // Structure to represent a candidate
    struct Candidate {
        string name;
        uint256 voteCount;
        bool exists;
    }
    
    // Mapping to store candidates by ID
    mapping(uint256 => Candidate) public candidates;
    
    // Mapping to track if an address has voted
    mapping(address => bool) public hasVoted;
    
    // Mapping to store voter's choice
    mapping(address => uint256) public voterChoice;
    
    // Array to store candidate IDs
    uint256[] public candidateIds;
    
    // Counter for candidate IDs
    uint256 public candidateCount;
    
    // Events
    event CandidateAdded(uint256 indexed candidateId, string name);
    event VoteCast(address indexed voter, uint256 indexed candidateId);
    event VotingStarted();
    event VotingEnded();
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier votingIsOpen() {
        require(votingOpen, "Voting is not currently open");
        _;
    }
    
    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "You have already voted");
        _;
    }
    
    modifier validCandidate(uint256 _candidateId) {
        require(candidates[_candidateId].exists, "Candidate does not exist");
        _;
    }
    
    // Constructor
    constructor() {
        admin = msg.sender;
        totalVotes = 0;
        votingOpen = false;
        candidateCount = 0;
    }
    
    /**
     * @dev Core Function 1: Add a new candidate to the voting
     * @param _name Name of the candidate
     */
    function addCandidate(string memory _name) 
        external 
        onlyAdmin 
    {
        require(!votingOpen, "Cannot add candidates while voting is open");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        
        candidateCount++;
        
        candidates[candidateCount] = Candidate({
            name: _name,
            voteCount: 0,
            exists: true
        });
        
        candidateIds.push(candidateCount);
        
        emit CandidateAdded(candidateCount, _name);
    }
    
    /**
     * @dev Core Function 2: Cast a vote for a candidate
     * @param _candidateId ID of the candidate to vote for
     */
    function castVote(uint256 _candidateId) 
        external 
        votingIsOpen 
        hasNotVoted 
        validCandidate(_candidateId) 
    {
        // Mark voter as having voted
        hasVoted[msg.sender] = true;
        voterChoice[msg.sender] = _candidateId;
        
        // Increment candidate's vote count
        candidates[_candidateId].voteCount++;
        
        // Increment total votes
        totalVotes++;
        
        emit VoteCast(msg.sender, _candidateId);
    }
    
    /**
     * @dev Core Function 3: Get voting results for a candidate
     * @param _candidateId ID of the candidate
     * @return candidateName Name of the candidate
     * @return voteCount Number of votes received
     */
    function getResults(uint256 _candidateId) 
        external 
        view 
        validCandidate(_candidateId) 
        returns (string memory candidateName, uint256 voteCount) 
    {
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.name, candidate.voteCount);
    }
    
    /**
     * @dev Start the voting process (admin only)
     */
    function startVoting() external onlyAdmin {
        require(candidateCount > 0, "No candidates added yet");
        require(!votingOpen, "Voting is already open");
        
        votingOpen = true;
        emit VotingStarted();
    }
    
    /**
     * @dev End the voting process (admin only)
     */
    function endVoting() external onlyAdmin {
        require(votingOpen, "Voting is not currently open");
        
        votingOpen = false;
        emit VotingEnded();
    }
    

    function getAllCandidates() 
        external 
        view 
        returns (
            uint256[] memory ids, 
            string[] memory names, 
            uint256[] memory voteCounts
        ) 
    {
        ids = new uint256[](candidateCount);
        names = new string[](candidateCount);
        voteCounts = new uint256[](candidateCount);
        
        for (uint256 i = 0; i < candidateCount; i++) {
            uint256 candidateId = candidateIds[i];
            ids[i] = candidateId;
            names[i] = candidates[candidateId].name;
            voteCounts[i] = candidates[candidateId].voteCount;
        }
        
        return (ids, names, voteCounts);
    }
    
    /**
     * @dev Get the winning candidate (can only be called after voting ends)
     * @return winnerId ID of the winning candidate
     * @return winnerName Name of the winning candidate
     * @return winnerVotes Number of votes received by winner
     */
    function getWinner() 
        external 
        view 
        returns (uint256 winnerId, string memory winnerName, uint256 winnerVotes) 
    {
        require(!votingOpen, "Voting is still ongoing");
        require(totalVotes > 0, "No votes have been cast");
        
        uint256 maxVotes = 0;
        uint256 winningCandidateId = 0;
        
        // Find candidate with most votes
        for (uint256 i = 0; i < candidateCount; i++) {
            uint256 candidateId = candidateIds[i];
            if (candidates[candidateId].voteCount > maxVotes) {
                maxVotes = candidates[candidateId].voteCount;
                winningCandidateId = candidateId;
            }
        }
        
        return (
            winningCandidateId,
            candidates[winningCandidateId].name,
            candidates[winningCandidateId].voteCount
        );
    }
    
    /**
     * @dev Check if voting is currently active
     * @return True if voting is open
     */
    function isVotingOpen() external view returns (bool) {
        return votingOpen;
    }
    
    /**
     * @dev Get total number of candidates
     * @return Number of candidates
     */
    function getTotalCandidates() external view returns (uint256) {
        return candidateCount;
    }
    
    /**
     * @dev Get voter information
     * @param _voter Address of the voter
     * @return voted Whether the voter has voted
     * @return candidateId ID of candidate voted for (0 if not voted)
     */
    function getVoterInfo(address _voter) 
        external 
        view 
        returns (bool voted, uint256 candidateId) 
    {
        return (hasVoted[_voter], voterChoice[_voter]);
    }
}
