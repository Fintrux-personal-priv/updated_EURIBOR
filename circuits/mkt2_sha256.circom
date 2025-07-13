pragma circom 2.0.0;

include "node_modules/circomlib/circuits/sha256/sha256.circom";
include "node_modules/circomlib/circuits/bitify.circom";

template HashLeftRight() {
    signal input L;
    signal input R;
    signal output H;

    signal bits[512];
    component lbits = Num2Bits(256);
    component rbits = Num2Bits(256);

    lbits.in <== L;
    rbits.in <== R;

    for (var i = 0; i < 256; i++) {
        bits[i]     <== lbits.out[255 - i];
        bits[i+256] <== rbits.out[255 - i];
    }

    component sha = Sha256Compress();
    sha.in <== bits;
    H <== sha.out;
}

template Level() {
    signal input sibling;
    signal input low;
    signal input selector;
    signal output root;

    signal left = selector == 0 ? low : sibling;
    signal right = selector == 0 ? sibling : low;

    component hlr = HashLeftRight();
    hlr.L <== left;
    hlr.R <== right;

    root <== hlr.H;
}

template Mkt2Verifier(nLevels) {
    signal input key;
    signal input value;
    signal input root;
    signal input siblings[nLevels];

    component n2b = Num2Bits(nLevels);
    n2b.in <== key;

    component levels[nLevels];

    for (var i = 0; i < nLevels; i++) {
        levels[i] = Level();
        levels[i].sibling  <== siblings[i];
        levels[i].selector <== n2b.out[i];
        levels[i].low      <== i == 0 ? value : levels[i-1].root;
    }

    root === levels[nLevels-1].root;
}

component main { public [root] } = Mkt2Verifier(10);
