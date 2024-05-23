// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Vote.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract VotingTest is Test {
    SimpleVotingSystem voting;
    address admin = address(1);
    address founder = address(2);
    address nonFounder = address(3);
    address voter1 = address(4);
    address voter2 = address(5);
    address voter3 = address(6);

    function setUp() public {
        voting = new SimpleVotingSystem();
        voting.grantRole(keccak256("ADMIN_ROLE"), admin);
        voting.grantRole(keccak256("FOUNDER_ROLE"), founder);

        // Envoyer de l'Ether au contrat de test pour couvrir les fonds nécessaires
        // payable(address(this)).transfer(10 ether);
    }

    function testAdminCanAddCandidate() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addAdmin(admin);  // Assuming admin can add himself just for testing setup
        voting.addCandidate("Alice");
        assertEq(voting.getCandidatesCount(), 1);
    }

    function testFailAddCandidateWhenNotAdmin() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        vm.prank(nonFounder);  // Using vm to simulate another address
        voting.addCandidate("Alice");
        assertEq(voting.getCandidatesCount(), 1);
    }

    function testFounderCanFundCandidate() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Bob");
        uint candidateId = 1;
        uint fundingAmount = 1 ether;
        vm.prank(founder);
        voting.fundCandidate{value: fundingAmount}(candidateId);
        assertEq(voting.getCandidate(candidateId).fundReceived, fundingAmount);
    }

    function testFailFundCandidateWhenNotFounder() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Charlie");
        uint candidateId = 1;
        uint fundingAmount = 1 ether;
        vm.prank(nonFounder);
        voting.fundCandidate{value: fundingAmount}(candidateId);  // Should fail
        assertEq(voting.getCandidate(candidateId).fundReceived, fundingAmount);
    }

    function testVoteNotAllowedBeforeOneHour() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        vm.prank(admin);
        voting.addCandidate("Alice");
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.stopPrank();

        vm.warp(block.timestamp + 30 minutes); // Advance time by 30 minutes
        vm.prank(voter1);
        vm.expectRevert("Voting is not allowed yet");
        voting.vote(1);

        vm.warp(block.timestamp + 31 minutes); // Advance to more than one hour
        vm.prank(voter1);
        voting.vote(1); // Now the vote should succeed
        assertEq(voting.getTotalVotes(1), 1, "Should have recorded one vote.");
    }

    function testVoting() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 61 minutes); // Advance to more than one hour
        vm.prank(voter1);
        voting.vote(1);  // Should pass now that we use the right address
        assertEq(voting.getTotalVotes(1), 1);
    }

    function testFailVoteNotInVoteStatus() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        vm.warp(block.timestamp + 61 minutes); // Advance to more than one hour
        vm.prank(voter1);
        voting.vote(1);  // This should fail because we are not in VOTE status
        assertEq(voting.getTotalVotes(1), 1); // Should still be 1
    }

    function testOnlyOnceVotingPerPerson() public {
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 61 minutes); // Advance to more than one hour
        vm.prank(voter1);
        voting.vote(1);     // Should pass and total votes should be 1
        voting.vote(1);  // This should fail because the same person cannot vote twice
        assertEq(voting.getTotalVotes(1), 1); // Should still be 1
    }

    function testDeclareWinner() public {
        vm.prank(admin);
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 1 hours + 1 seconds);
        
        vm.prank(voter1);
        voting.vote(1);  // Vote for Alice
        
        vm.prank(voter2);
        voting.vote(2);  // Vote for Bob

        vm.prank(voter3);
        voting.vote(2);  // Vote for Bob again

        vm.prank(admin);
        voting.completeVoting();

        SimpleVotingSystem.Candidate memory winner = voting.declareWinner();
        assertEq(winner.name, "Bob");
        assertEq(winner.voteCount, 2);
    }
}
