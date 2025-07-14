# Merkle Tree Verification Circuit for Secure MPC Protocol

This project implements a Circom circuit for verifying membership in a Merkle tree, a crucial component of a secure Multi-Party Computation (MPC) protocol designed for the confidential aggregation of financial data (e.g., interest rates) among participating banks. The circuit ensures that secret shares distributed among banks are correctly included in a Merkle tree, providing integrity and confidentiality guarantees as part of the broader protocol outlined in **"FormalDescriptionProtocol\_EURIBOR.pdf."**

---

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Circuit Description](#circuit-description)
- [Setup and Installation](#setup-and-installation)
- [Usage](#usage)
  - [Compiling the Circuit](#compiling-the-circuit)
  - [Generating Witness and Proof](#generating-witness-and-proof)
  - [Verifying the Proof](#verifying-the-proof)
- [Integration with MPC Protocol](#integration-with-mpc-protocol)

---

## Overview

The Merkle tree verification circuit is a key element in ensuring the security of the MPC protocol. It allows banks to verify that their secret shares are correctly included in the Merkle tree constructed by each participant, without revealing the shares themselves. This verification is essential for maintaining the confidentiality and integrity of the aggregated data.

This upgraded implementation:

- Uses **SHA-256** for all Merkle tree and proof computations, replacing Poseidon.
- Is implemented in **Circom**, a domain-specific language for defining arithmetic circuits used in zero-knowledge proof systems.
- Provides reproducible, automated builds and tests using Docker and Node.js tooling.

---

## Project Structure

```
updated_EURIBOR/
├── Dockerfile
├── .gitignore
├── README.md
├── package.json
├── package-lock.json
├── circuits/
│   ├── mkt2.circom           # Legacy Poseidon-based circuit (for reference)
│   └── mkt2_sha256.circom    # Main circuit for Merkle tree verification (SHA-256)
├── scripts/
│   ├── merkle.js             # Merkle tree utilities (JS)
│   ├── compile.sh            # Circuit compilation helper script
│   └── setup.sh              # Trusted setup automation script
├── test/
│   ├── merkle.test.js        # Legacy Poseidon test (for reference)
│   └── merkle_big.test.js    # SHA-256 Merkle tree proof test (scalable)
├── docs/
│   └── FormalDescriptionProtocol_EURIBOR.pdf
└── .github/
    └── workflows/
        └── test.yml          # CI pipeline
```

---

## Circuit Description

The circuit `mkt2_sha256.circom` verifies that a given leaf value is part of a Merkle tree at a specified position using zero-knowledge proofs. It supports a Merkle tree with a configurable number of levels (default: 10, allowing for 1024 leaves).

### Key Components

- **HashLeftRight**: Computes SHA-256 hash of two 256-bit inputs, big-endian, as required for Merkle path verification.
- **Level**: Verifies a single Merkle tree level. Handles correct left/right (sibling/low) ordering via selector bits and applies SHA-256.
- **Mkt2Verifier**: Main template that iterates through all levels, computing the root hash from the leaf up and verifying it against the provided root.

### Inputs

- `key`: Position of the leaf in the tree (0 to N-1 for N leaves)
- `value`: SHA-256 hash of the secret share (leaf value)
- `root`: Merkle tree root (public input)
- `siblings`: Array of sibling hashes along the path from the leaf to the root

### Outputs

- The circuit checks if the computed root matches the provided root, ensuring the leaf is correctly included in the tree.

---

## Setup and Installation

### Prerequisites

- Docker (recommended for reproducibility)
- Node.js (v16+)

### One-Command Setup (Docker)

```bash
git clone https://github.com/Fintrux-personal-priv/updated_EURIBOR.git
cd updated_EURIBOR
docker build -t euribor-zkp .
docker run --rm -it euribor-zkp
```

This will provide a container with Circom, snarkjs, and all dependencies preinstalled.

### Manual Installation (Alternative)

```bash
npm install
npm install circomlib
```

Install Circom and snarkjs globally if not using Docker:

```bash
npm install -g snarkjs
# Follow Circom install docs: https://docs.circom.io/getting-started/installation/
```

---

## Usage

### Compiling the Circuit

To compile the SHA-256 circuit:

```bash
bash scripts/compile.sh
# Or manually:
circom circuits/mkt2_sha256.circom --r1cs --wasm -l node_modules
```

This generates:

- `circuits/mkt2_sha256.r1cs`: Circuit constraints
- `mkt2_sha256_js/mkt2_sha256.wasm`: WASM for witness generation

### Generating Witness and Proof

Prepare an input file `input_big.json`:

```json
{
  "key": 123,
  "value": "...",         // 256-bit leaf value (as a decimal string)
  "root": "...",          // Merkle root (as a decimal string)
  "siblings": ["...", "..."], // Array of sibling values (decimal strings)
}
```

Run witness generation:

```bash
node mkt2_sha256_js/generate_witness.js mkt2_sha256_js/mkt2_sha256.wasm input_big.json witness.wtns
```

#### Trusted Setup and Proof Generation

Automate using `scripts/setup.sh`, or run manually:

```bash
bash scripts/setup.sh
# or step-by-step:
snarkjs groth16 setup circuits/mkt2_sha256.r1cs powersOfTau28_hez_final_10.ptau mkt2_sha256_0000.zkey
snarkjs zkey contribute mkt2_sha256_0000.zkey mkt2_sha256_0001.zkey --name="1st Contributor" -v -e="random text"
snarkjs zkey export verificationkey mkt2_sha256_0001.zkey verification_key.json
snarkjs groth16 prove mkt2_sha256_0001.zkey witness.wtns proof.json public.json
```

### Verifying the Proof

```bash
snarkjs groth16 verify verification_key.json public.json proof.json
```

If the proof is valid, the output will be `[OK]`.

---

## Integration with MPC Protocol

This circuit is integrated into the broader MPC protocol as follows:

- **Secret Sharing Phase**: Each bank constructs a Merkle tree for its secret shares and posts the root to the bulletin board.
- **Verification**: Other banks use this circuit to verify that the shares they receive are correctly included in the Merkle tree, ensuring the shares' integrity without revealing the shares themselves.

The circuit's use of **SHA-256** hashing ensures compatibility with common standards and blockchain audit trails, while maintaining ZKP security and efficiency.

---

## Acknowledgements

- Based on "FormalDescriptionProtocol\_EURIBOR.pdf" (see `docs/`)
- Uses [circom](https://github.com/iden3/circom) and [circomlib](https://github.com/iden3/circomlib)
- ZKP workflow based on [snarkjs](https://github.com/iden3/snarkjs)

