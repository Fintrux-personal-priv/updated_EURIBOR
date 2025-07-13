import { createHash } from 'crypto';

/** deterministic SHA256(left||right) as bigint */
export function hashLR(l, r) {
  const h = createHash('sha256');
  h.update(BigInt(l).toString(16).padStart(64, '0') + BigInt(r).toString(16).padStart(64, '0'), 'hex');
  return BigInt('0x' + h.digest('hex'));
}

/** Build tree and expose root + siblings for any leaf index */
export function buildTree(leaves) {
  if (leaves.length & (leaves.length - 1))
    throw new Error('power-of-two leaves required');

  const layers = [leaves.map(BigInt)];
  while (layers[layers.length - 1].length > 1) {
    const prev = layers[layers.length - 1];
    const next = [];
    for (let i = 0; i < prev.length; i += 2)
      next.push(hashLR(prev[i], prev[i + 1]));
    layers.push(next);
  }
  return {
    root: layers[layers.length - 1][0],
    siblings(index) {
      const sibs = [];
      let idx = index;
      for (let d = 0; d < layers.length - 1; d++) {
        sibs.push(layers[d][idx ^ 1n]);
        idx >>= 1n;
      }
      return sibs;
    }
  };
}
