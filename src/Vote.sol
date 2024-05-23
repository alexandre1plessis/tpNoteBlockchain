// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleVotingSystem is AccessControl {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    enum WorkflowStatus { REGISTER_CANDIDATES, FOUND_CANDIDATES, VOTE, COMPLETED }
    WorkflowStatus public currentStatus;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Only an admin can perform this action");
        _;
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only the contract owner can perform this action");
        _;
    }

    modifier inStatus(WorkflowStatus _status) {
        require(currentStatus == _status, "Invalid operation at current workflow status");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        currentStatus = WorkflowStatus.REGISTER_CANDIDATES;
    }

    function setWorkflowStatus(WorkflowStatus _status) public onlyAdmin {
        currentStatus = _status;
    }

    function addCandidate(string memory _name) public onlyAdmin inStatus(WorkflowStatus.REGISTER_CANDIDATES) {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
    }

    function vote(uint _candidateId) public inStatus(WorkflowStatus.VOTE) {
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
    }

    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }
 
    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }
 
    // Optional: Function to get candidate details by ID
    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }
}
