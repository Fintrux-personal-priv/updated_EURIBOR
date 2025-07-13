import { buildTree, randomLeaves } from '../scripts/merkle.js';
import fs from 'fs';
import { execSync } from 'child_process';

const N = 1024;
const idx = 123;

test('SHA256 Merkle circuit proof for big tree', () => {
  const leaves = randomLeaves(N);
  const { root, siblings } = buildTree(leaves);

  // Prepare circuit input
  const input = {
    key: idx,
    value: leaves[idx].toString(),
    root: root.toString(),
    siblings: siblings(idx).map(x => x.toString())
  };
  fs.writeFileSync('input_big.json', JSON.stringify(input, null, 2));

  // Compile circuit
  execSync('circom circuits/mkt2_sha256.circom --r1cs --wasm -l node_modules', { stdio: 'inherit' });

  // Generate witness
  execSync('node mkt2_sha256_js/generate_witness.js mkt2_sha256_js/mkt2_sha256.wasm input_big.json witness.wtns', { stdio: 'inherit' });

});
