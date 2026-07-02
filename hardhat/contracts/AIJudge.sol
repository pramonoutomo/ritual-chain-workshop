// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PrivacyBountyJudge {
    struct Bounty {
        address creator;
        uint256 submissionEnd;
        uint256 revealEnd;
        bool judgingStarted;
        uint256 winnerIndex;
    }

    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => mapping(address => bytes32)) public commitments;
    mapping(uint256 => mapping(address => string)) public revealedAnswers;
    mapping(uint256 => address[]) public revealedParticipants;

    uint256 public nextBountyId = 1;

    event BountyCreated(uint256 indexed bountyId, address creator, uint256 submissionEnd, uint256 revealEnd);
    event CommitmentSubmitted(uint256 indexed bountyId, address indexed participant, bytes32 commitment);
    event AnswerRevealed(uint256 indexed bountyId, address indexed participant);
    event JudgingStarted(uint256 indexed bountyId);
    event WinnerFinalized(uint256 indexed bountyId, uint256 winnerIndex, address winner);

    // Buat bounty baru (bisa ditambahkan)
    function createBounty(uint256 submissionDuration, uint256 revealDuration) external returns (uint256) {
        uint256 bountyId = nextBountyId++;
        bounties[bountyId] = Bounty({
            creator: msg.sender,
            submissionEnd: block.timestamp + submissionDuration,
            revealEnd: block.timestamp + submissionDuration + revealDuration,
            judgingStarted: false,
            winnerIndex: 0
        });
        emit BountyCreated(bountyId, msg.sender, bounties[bountyId].submissionEnd, bounties[bountyId].revealEnd);
        return bountyId;
    }

    // === REQUIRED FUNCTIONS ===

    function submitCommitment(uint256 bountyId, bytes32 commitment) external {
        require(block.timestamp < bounties[bountyId].submissionEnd, "Submission closed");
        require(commitments[bountyId][msg.sender] == bytes32(0), "Already committed");
        
        commitments[bountyId][msg.sender] = commitment;
        emit CommitmentSubmitted(bountyId, msg.sender, commitment);
    }

    function revealAnswer(uint256 bountyId, string calldata answer, bytes32 salt) external {
        require(block.timestamp >= bounties[bountyId].submissionEnd, "Reveal not started");
        require(block.timestamp < bounties[bountyId].revealEnd, "Reveal period ended");
        
        bytes32 storedCommitment = commitments[bountyId][msg.sender];
        require(storedCommitment != bytes32(0), "No commitment found");
        require(bytes(revealedAnswers[bountyId][msg.sender]).length == 0, "Already revealed");

        bytes32 computed = keccak256(abi.encodePacked(answer, salt, msg.sender, bountyId));
        require(computed == storedCommitment, "Invalid reveal: hash mismatch");

        revealedAnswers[bountyId][msg.sender] = answer;
        revealedParticipants[bountyId].push(msg.sender);
        emit AnswerRevealed(bountyId, msg.sender);
    }

    function judgeAll(uint256 bountyId, bytes calldata llmInput) external {
        require(msg.sender == bounties[bountyId].creator || msg.sender == address(this), "Only creator");
        require(!bounties[bountyId].judgingStarted, "Judging already started");
        require(block.timestamp > bounties[bountyId].revealEnd, "Reveal period not finished");

        bounties[bountyId].judgingStarted = true;
        emit JudgingStarted(bountyId);
        
        // Dalam praktik: emit event berisi semua revealed answers + llmInput
        // Off-chain agent / Ritual listener akan ambil data ini lalu panggil LLM
    }

    function finalizeWinner(uint256 bountyId, uint256 winnerIndex) external {
        require(bounties[bountyId].judgingStarted, "Judging not started yet");
        require(winnerIndex < revealedParticipants[bountyId].length, "Invalid winner index");

        bounties[bountyId].winnerIndex = winnerIndex;
        address winner = revealedParticipants[bountyId][winnerIndex];
        emit WinnerFinalized(bountyId, winnerIndex, winner);
    }

    // Helper function (penting untuk LLM)
    function getRevealedAnswers(uint256 bountyId) external view returns (string[] memory answers, address[] memory participants) {
        return (revealedAnswersList(bountyId), revealedParticipants[bountyId]);
    }

    // internal helper
    function revealedAnswersList(uint256 bountyId) internal view returns (string[] memory) {
        address[] memory parts = revealedParticipants[bountyId];
        string[] memory ans = new string[](parts.length);
        for (uint i = 0; i < parts.length; i++) {
            ans[i] = revealedAnswers[bountyId][parts[i]];
        }
        return ans;
    }
}
