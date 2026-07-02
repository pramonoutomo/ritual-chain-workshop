## Starter for Ritual workshop on 23th June 2026

# Privacy-Preserving AI Bounty Judge - Ritual Chain Workshop

Implementasi Commit-Reveal scheme untuk menyembunyikan submission bounty hingga fase reveal selesai.

## Overview
Project ini memperbaiki kelemahan bounty judge dari Bootcamp #1 di mana submission bersifat public. Peserta hanya mengirim commitment hash, baru reveal jawaban setelah deadline.

## Features
- Commit-Reveal flow (Required Track)
- Support multiple bounties
- Time-based validation (submission & reveal window)
- Integration-ready dengan LLM judging via `judgeAll`
- Helper functions untuk batch revealed answers

## Contract Architecture

### Lifecycle
1. **Create Bounty** → Owner buat bounty dengan submission + reveal duration
2. **Submission Phase** → Peserta submit `commitment = keccak256(answer + salt + msg.sender + bountyId)`
3. **Reveal Phase** → Peserta reveal answer + salt, contract verifikasi hash
4. **Judging Phase** → Creator panggil `judgeAll()` → emit event untuk off-chain / Ritual LLM
5. **Finalize** → Tentukan pemenang berdasarkan hasil judging

### Key Functions
- `submitCommitment(uint256 bountyId, bytes32 commitment)`
- `revealAnswer(uint256 bountyId, string calldata answer, bytes32 salt)`
- `judgeAll(uint256 bountyId, bytes calldata llmInput)`
- `finalizeWinner(uint256 bountyId, uint256 winnerIndex)`

## Security Considerations
- Commit-Reveal mencegah front-running & copy-paste submission
- Salt unik per submission
- Time window protection
- Access control pada judging & finalize

## Testing
Semua test case berhasil:
- Valid & invalid reveal
- Time window enforcement
- Double commit/reveal protection
- Judging flow

Jalankan test: `npx hardhat test`

## Deployment
- Local Hardhat: `npx hardhat run scripts/deploy.js --network localhost`
- Ritual Testnet: (lihat panduan di bawah)

## Reflection Question

**What should be public, what should stay hidden, and what should be decided by AI versus by a human in a bounty system?**

Dalam sistem bounty yang adil, deskripsi bounty, deadline, dan pemenang akhir seharusnya publik agar transparan. Namun isi jawaban/submission harus tetap tersembunyi selama fase submission dan reveal agar tidak ada yang bisa menjiplak ide. Commitment hash baru terlihat setelah reveal.

AI sangat efektif untuk **penilaian awal batch** (cepat, konsisten, skalabel). Manusia lebih baik untuk keputusan final, menangani nuansa kreativitas, etika, dan edge cases. Pendekatan hybrid (AI + human review) adalah solusi terbaik.

**Author**: [Nama Kamu]  
**Date**: July 2026  
**Ritual Academy - Bootcamp #1 Follow-up**
