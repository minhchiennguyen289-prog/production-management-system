# ============================================================

# CREATE answers.md

# ============================================================

answers = """# LAB 03 — HASH, MERKLE TREE & DIGITAL SIGNATURES

**Full Name:** Nguyen Minh Chien  
**Student ID:** 11247146  
**Class / Group:** DS66A

---

## Q1 — Proof-of-Work Difficulty

Each extra leading hexadecimal zero increases the expected work by approximately **16 times**.

SHA-256 is displayed in hexadecimal, where each position has 16 possible values.  
The probability that one hexadecimal digit is `0` is `1/16`.

Therefore, for `k` leading zeros:

P = (1/16)^k

Adding one more required zero reduces the probability of success by 16 times, so the expected number of hash attempts increases by approximately **16×**.

---

## Q2 — Proof-of-Work Verification

Verifying a discovered nonce requires only **one hash calculation**.

The verifier computes:

SHA256(data + nonce)

and checks whether the resulting hash starts with the required number of zeros.

This demonstrates the asymmetric property of Proof-of-Work:

- Finding a valid nonce can require millions of hash calculations.
- Verifying the nonce is fast and inexpensive.

Therefore, PoW is **expensive to produce but cheap to verify**.

---

## Q3 — Merkle Proof Size

For `n = 1,000,000` transactions, one Merkle proof contains approximately:

ceil(log2(1,000,000)) = 20 hashes

A Merkle Tree is a binary tree, so the proof length grows logarithmically with the number of transactions.

Therefore, a Merkle proof for one transaction among 1,000,000 transactions requires approximately **20 hashes**.

This shows that Merkle proofs are efficient because their size grows as **O(log n)** instead of O(n).

---

## Q4 — Real-World Application

A real-world application of Merkle proofs is **Simplified Payment Verification (SPV) in Bitcoin**.

Lightweight Bitcoin wallets do not need to download every transaction in the blockchain. Instead, they store block headers, which contain the Merkle Root of each block.

To verify that a transaction belongs to a block, the wallet obtains:

1. The transaction hash.
2. A Merkle proof.
3. The Merkle Root contained in the block header.

The wallet combines the transaction hash with the sibling hashes in the Merkle proof until it calculates the Merkle Root.

If the calculated root matches the Merkle Root in the block header, the transaction is verified as belonging to that block.

This allows lightweight wallets to verify transactions without downloading the entire block.

---

# PART 3 — DIGITAL SIGNATURES

## 3.1 — Sign and Recover

A message is signed using a private key.

The signature can then be used with the original message to recover the Ethereum address of the signer.

If:

recovered_address == signer_address

then the signature is valid.

This proves that the signer owns the corresponding private key without revealing the private key itself.

---

## 3.2 — Tampered Message

If only one character of the original message is changed while keeping the same signature, the recovered address becomes different from the original signer address.

This happens because changing the message changes its hash completely due to the **avalanche effect**.

Therefore:

Original message + signature  
→ Correct signer address

Modified message + same signature  
→ Different recovered address

Because the recovered address no longer matches the expected signer, verification fails.

This demonstrates the **integrity** property of digital signatures: modifying the signed data invalidates the signature.

---

## 3.3 — Same Message Signed Twice

When the **same private key** signs the **same message** twice, the resulting signatures are identical.

**IDENTICAL? YES**

**RFC:** RFC 6979 — Deterministic Usage of DSA and ECDSA

RFC 6979 defines deterministic nonce generation for ECDSA.

Instead of choosing a completely random nonce for every signature, the nonce is deterministically generated from the private key and the message hash.

Therefore:

Same private key + Same message = Same signature

If the message changes, its hash changes, which produces a different signature.

Deterministic nonce generation also reduces the risk of private-key leakage caused by weak or reused random nonces.

---

# Summary

| Topic                                   | Result                                    |
| --------------------------------------- | ----------------------------------------- |
| Extra PoW leading zero                  | Expected work increases approximately 16× |
| PoW verification                        | 1 hash calculation                        |
| Merkle proof for 1,000,000 transactions | Approximately 20 hashes                   |
| Real-world Merkle application           | Bitcoin SPV                               |
| Tampered signed message                 | Recovered address changes                 |
| Same key + same message                 | Identical signature                       |
| Deterministic ECDSA standard            | RFC 6979                                  |

"""

with open("answers.md", "w", encoding="utf-8") as f:
f.write(answers)

print("✅ answers.md created successfully!")
