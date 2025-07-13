#!/bin/bash
set -e

# Compile the SHA256-based Merkle root circuit
circom circuits/mkt2_sha256.circom --r1cs --wasm -l node_modules

echo "Compilation complete: .r1cs and .wasm files are ready."
