#!/bin/bash
set -e

# Trusted setup for Groth16 using pre-generated Powers-Of-Tau file

PTAU="powersOfTau28_hez_final_10.ptau"
ZKEY0="mkt2_sha256_0000.zkey"
ZKEY1="mkt2_sha256_0001.zkey"

# Download ptau if missing
if [ ! -f "$PTAU" ]; then
  echo "Downloading Powers-of-Tau file..."
  wget https://hermez.s3-eu-west-1.amazonaws.com/$PTAU
else
  echo "Powers-of-Tau file already exists."
fi

# Start ceremony
snarkjs groth16 setup circuits/mkt2_sha256.r1cs $PTAU $ZKEY0

# Contribute randomness to zkey
snarkjs zkey contribute $ZKEY0 $ZKEY1 \
  --name="1st Contributor" -v -e="random text"

# Export verification key
snarkjs zkey export verificationkey $ZKEY1 verification_key.json

echo "Trusted setup complete. Files generated:"
echo "- $ZKEY1"
echo "- verification_key.json"
