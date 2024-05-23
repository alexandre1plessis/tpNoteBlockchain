// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimpleVotingSystem is AccessControl {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    enum WorkflowStatus { REGISTERCANDIDATES, FOUND_CANDIDATES, VOTE, COMPLETED }
    WorkflowStatus public status;

    address public owner;
    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "Restricted to specific role");
        ;
    }

    constructor() {
        owner = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function addCandidate(string memory _name) public onlyRole(ADMIN_ROLE) {
        require(status == WorkflowStatus.REGISTER_CANDIDATES, "Not the right time to add candidates");
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
    }

    function vote(uint _candidateId) public {
        require(status == WorkflowStatus.VOTE, "Voting is not active");
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
    }

    // Implement other functions and modify as needed based on the tasks above
}
