pragma circom 2.0.0;

// Include necessary libraries from circomlib
include "node_modules/circomlib/circuits/switcher.circom";
include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/bitify.circom";

// Template for verifying a single level of the Merkle tree
template Mkt2VerifierLevel() {
    signal input sibling;  // Sibling node hash
    signal input low;      // Lower node hash (from previous level)
    signal input selector; // Selector bit (0 or 1) to choose left or right
    signal output root;    // Computed root hash for this level

    // Use Switcher to select between low and sibling based on selector
    component sw = Switcher();
    sw.sel <== selector;
    sw.L <== low;
    sw.R <== sibling;

    // Hash the selected pair using Poseidon
    component hash = Poseidon(2);
    hash.inputs[0] <== sw.outL;
    hash.inputs[1] <== sw.outR;

    // Output the hash as the root for this level
    root <== hash.out;
}

// Main template for verifying Merkle tree membership
template Mkt2Verifier(nLevels) {
    signal input key;         // Position of the leaf in the tree
    signal input value;       // Hash of the share (leaf value)
    signal input root;        // Root of the Merkle tree (public)
    signal input siblings[nLevels]; // Sibling hashes along the path

    // Hash the value to get the leaf hash
    component hashV = Poseidon(1);
    hashV.inputs[0] <== value;

    // Convert key to binary to determine the path
    component n2b = Num2Bits(nLevels);
    n2b.in <== key;

    // Array of level verifiers
    component levels[nLevels];

    // Set up each level
    for (var i = nLevels - 1; i >= 0; i--) {
        levels[i] = Mkt2VerifierLevel();
        levels[i].sibling <== siblings[i];
        levels[i].selector <== n2b.out[i];
        if (i == nLevels - 1) {
            levels[i].low <== hashV.out; // For the last level, low is the leaf hash
        } else {
            levels[i].low <== levels[i + 1].root; // For other levels, low is the root from the next level
        }
    }

    // Check that the computed root matches the provided root
    root === levels[0].root;
}

// Instantiate the main component with 3 levels, making root public
component main { public [root] } = Mkt2Verifier(3);
