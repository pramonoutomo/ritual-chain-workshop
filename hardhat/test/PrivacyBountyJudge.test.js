const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("PrivacyBountyJudge", function () {
  let contract, owner, user1, user2;
  let bountyId;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("PrivacyBountyJudge");
    contract = await Factory.deploy();
    await contract.waitForDeployment();

    // Buat bounty (submission 1 jam, reveal 30 menit)
    const tx = await contract.createBounty(3600, 1800);
    const receipt = await tx.wait();
    bountyId = receipt.logs[0].args.bountyId; // ambil dari event
  });

  it("Should create bounty successfully", async function () {
    expect(bountyId).to.be.gt(0);
    const bounty = await contract.bounties(bountyId);
    expect(bounty.creator).to.equal(owner.address);
  });

  it("Should allow submit commitment", async function () {
    const salt = ethers.randomBytes(32);
    const answer = "My secret solution 123";
    const commitment = ethers.keccak256(
      ethers.solidityPacked(["string", "bytes32", "address", "uint256"], 
        [answer, salt, user1.address, bountyId])
    );

    await expect(contract.connect(user1).submitCommitment(bountyId, commitment))
      .to.emit(contract, "CommitmentSubmitted");

    expect(await contract.commitments(bountyId, user1.address)).to.equal(commitment);
  });

  it("Should reject double commitment", async function () {
    // ... submit pertama
    const salt = ethers.randomBytes(32);
    const commitment = ethers.keccak256(/* ... */);
    await contract.connect(user1).submitCommitment(bountyId, commitment);

    await expect(contract.connect(user1).submitCommitment(bountyId, commitment))
      .to.be.revertedWith("Already committed");
  });

  it("Should allow valid reveal and reject invalid", async function () {
    // Submit commitment dulu
    const salt = ethers.randomBytes(32);
    const answer = "My secret solution 123";
    const commitment = ethers.keccak256(
      ethers.solidityPacked(["string", "bytes32", "address", "uint256"], 
        [answer, salt, user1.address, bountyId])
    );
    await contract.connect(user1).submitCommitment(bountyId, commitment);

    // Majukan waktu ke reveal phase
    await time.increase(3700);

    // Valid reveal
    await expect(contract.connect(user1).revealAnswer(bountyId, answer, salt))
      .to.emit(contract, "AnswerRevealed");

    // Invalid salt
    await expect(contract.connect(user1).revealAnswer(bountyId, answer, ethers.randomBytes(32)))
      .to.be.revertedWith("Invalid reveal: hash mismatch");
  });

  it("Should reject reveal outside time window", async function () {
    // Reveal terlalu cepat
    const salt = ethers.randomBytes(32);
    const answer = "test";
    const commitment = /* ... */;
    await contract.connect(user1).submitCommitment(bountyId, commitment);

    await expect(contract.connect(user1).revealAnswer(bountyId, answer, salt))
      .to.be.revertedWith("Reveal not started");
  });

  it("Should allow judgeAll only by creator after reveal end", async function () {
    await time.increase(4000); // lewati reveal end

    await expect(contract.judgeAll(bountyId, "0x"))
      .to.emit(contract, "JudgingStarted");

    await expect(contract.connect(user1).judgeAll(bountyId, "0x"))
      .to.be.revertedWith("Only creator");
  });

  it("Should finalize winner correctly", async function () {
    // Reveal beberapa user dulu (simulasi)
    await time.increase(4000);

    await contract.judgeAll(bountyId, "0x");

    await expect(contract.finalizeWinner(bountyId, 0))
      .to.emit(contract, "WinnerFinalized");
  });

  it("getRevealedAnswers should return correct data", async function () {
    // ... setelah reveal user1 dan user2
    const [answers, participants] = await contract.getRevealedAnswers(bountyId);
    expect(answers.length).to.be.gt(0);
  });
});
