// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "ds-test/test.sol";
import "../src/Vote.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract VotingTest is DSTest {
    SimpleVotingSystem voting;
    address admin = address(1);
    address voter = address(2);

    function setUp() public {
        voting = new SimpleVotingSystem();
        voting.grantRole(keccak256("ADMIN_ROLE"), admin);
    }

    function testAdminCanAddCandidate() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addAdmin(admin);  // Assuming admin can add himself just for testing setup
        voting.addCandidate("Alice");
        assertEq(voting.getCandidatesCount(), 1);
    }

    function testFailAddCandidateWhenNotAdmin() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
    }

    function testVoting() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        voting.vote(1);  // This should fail as we are not using the right voter address
    }

    function testFailVoteNotInVoteStatus() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        voting.vote(1);  // This should fail because we are not in VOTE status
    }

    function testOnlyOnceVotingPerPerson() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        voting.vote(1);
        voting.vote(1);  // This should fail because the same person cannot vote twice
    }

    function testCorrectVoteCounting() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        voting.vote(1);
        assertEq(voting.getTotalVotes(1), 1);
    }
}
