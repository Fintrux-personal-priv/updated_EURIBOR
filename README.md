
# Merkle Tree Verification Circuit for Secure MPC Protocol

This project implements a Circom circuit for verifying membership in a Merkle tree, a crucial component of a secure Multi-Party Computation (MPC) protocol designed for the confidential aggregation of financial data (e.g., interest rates) among participating banks. The circuit ensures that secret shares distributed among banks are correctly included in a Merkle tree, providing integrity and confidentiality guarantees as part of the broader protocol outlined in **"FormalDescriptionProtocol_EURIBOR.pdf."**

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
- [Contributing](#contributing)
- [License](#license)

## Overview

The Merkle tree verification circuit is a key element in ensuring the security of the MPC protocol. It allows banks to verify that their secret shares are correctly included in the Merkle tree constructed by each participant, without revealing the shares themselves. This verification is essential for maintaining the confidentiality and integrity of the aggregated data.

The circuit is implemented in **Circom**, a domain-specific language for defining arithmetic circuits used in zero-knowledge proof systems. It leverages components from **circomlib**, including `switcher.circom`, `poseidon.circom`, and `bitify.circom`, to efficiently compute and verify Merkle tree paths.

## Project Structure

```
circuits/        # Circom circuit files
    mkt2.circom  # Main circuit for Merkle tree verification

scripts/         # Shell scripts for automation (compilation, setup, proof generation)
test/            # Test files and example inputs
docs/            # Additional documentation and protocol specifications
README.md        # Project overview and usage instructions
```

## Circuit Description

The circuit `mkt2.circom` verifies that a given leaf value is part of a Merkle tree at a specified position using zero-knowledge proofs. It supports a Merkle tree with a configurable number of levels (default: 3, allowing for 8 leaves).

### Key Components

- **Mkt2VerifierLevel**: Template for verifying a single level of the Merkle tree. It uses a Switcher to conditionally order the low and sibling hashes based on the selector bit and computes the hash using Poseidon.
- **Mkt2Verifier**: Main template that iterates through each level of the tree, computing the root hash from the leaf up and verifying it against the provided root.

### Inputs

- `key`: Position of the leaf in the tree (0 to 7 for 3 levels)
- `value`: Hash of the secret share (leaf value)
- `root`: Root of the Merkle tree (public)
- `siblings`: Array of sibling hashes along the path from the leaf to the root

### Outputs

- The circuit checks if the computed root matches the provided root, ensuring the leaf is correctly included in the tree.

## Setup and Installation

### Install Dependencies

- Install Circom: Follow the instructions at [Circom Installation](https://docs.circom.io/getting-started/installation/)
- Install snarkjs:
  ```bash
  npm install -g snarkjs
  ```
- Install Node.js (required for witness computation)

### Clone the Repository

```bash
git clone https://github.com/your-repo/merkle-tree-verification.git
cd merkle-tree-verification
```

### Install Circuit Dependencies

```bash
npm install circomlib
```

## Usage

### Compiling the Circuit

To compile the circuit, run:

```bash
circom circuits/mkt2.circom --r1cs --wasm --sym -l node_modules
```

This generates:

- `mkt2.r1cs`: Constraint system
- `mkt2_js/mkt2.wasm`: WebAssembly for witness generation
- `mkt2.sym`: Symbols for debugging

### Generating Witness and Proof

Prepare an input file `input.json`:

```json
{
  "key": "2",
  "value": "12345678901234567890",
  "root": "98765432109876543210",
  "siblings": [
    "11111111111111111111",
    "22222222222222222222",
    "33333333333333333333"
  ]
}
```

Compute the witness:

```bash
node mkt2_js/generate_witness.js mkt2_js/mkt2.wasm input.json witness.wtns
```

#### Trusted Setup

Perform the trusted setup (or use Powers of Tau ceremony results). You can automate this using `scripts/setup.sh`.

Generate the proof:

```bash
snarkjs groth16 prove mkt2_0001.zkey witness.wtns proof.json public.json
```

### Verifying the Proof

To verify the proof:

```bash
snarkjs groth16 verify verification_key.json public.json proof.json
```

If the proof is valid, the output will be `[OK]`.

## Integration with MPC Protocol

This circuit is integrated into the broader MPC protocol as follows:

- **Secret Sharing Phase**:
  Each bank constructs a Merkle tree for its secret shares and posts the root to the bulletin board.

- **Verification**:
  Other banks use this circuit to verify that the shares they receive are correctly included in the Merkle tree, ensuring the shares' integrity without revealing the shares themselves.

The circuit's use of **Poseidon** hashing ensures efficiency within the zero-knowledge proof system, aligning with the protocol's security and performance requirements.
