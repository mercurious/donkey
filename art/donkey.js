// Voxel donkey head for Donkey's icon and artwork, built for VOXEL GT's
// mesher (VoxelGrid + meshGrid from mercurious/voxel-gt-opus src/voxel.js).
// x runs left to right, y up, z towards the viewer. Everything is built on
// the left and mirrored, so the face is exactly symmetric. Tuned for 32 px:
// big ears, a pale muzzle, dark nostrils and pale-ringed eyes are what read
// as "donkey" that small, so they are oversized.

export const COATS = {
  grey: { coat: '#8d8379', coatDark: '#6a625b', muzzle: '#ece3d6', ear: '#d9c4b8', tip: '#2b2420', mane: '#3a322d' },
  brown: { coat: '#8a6446', coatDark: '#664831', muzzle: '#efe2cc', ear: '#dcb6a2', tip: '#271c15', mane: '#30231a' },
  dun: { coat: '#b49572', coatDark: '#8f7356', muzzle: '#f3eadb', ear: '#e6cab6', tip: '#352719', mane: '#45321f' },
};

const P = { coat: 1, coatDark: 2, muzzle: 3, ear: 4, tip: 5, mane: 6, eye: 7, shine: 8, nostril: 9, mouth: 10 };

function palette(c) {
  return [c.coat, c.coatDark, c.muzzle, c.ear, c.tip, c.mane, '#15110e', '#ffffff', '#2a1f1a', '#5c4b40']
    .map((color) => ({ color, group: 0 }));
}

export const SIZE = { nx: 28, ny: 37, nz: 14 };
const MID = SIZE.nx - 1; // mirror: x <-> MID - x

/**
 * opts.coat: key of COATS; opts.grin: show a mouth line;
 * opts.earLean: outward lean, voxels per 4 rows (default 1).
 */
export function buildDonkey(VoxelGrid, opts = {}) {
  const c = COATS[opts.coat || 'grey'];
  const lean = opts.earLean ?? 1;
  const g = new VoxelGrid(SIZE.nx, SIZE.ny, SIZE.nz);
  const sym = (x, y, z, v) => { g.set(x, y, z, v); g.set(MID - x, y, z, v); };

  // Head, left half: rows y 1..21, columns from `left` to the middle.
  // Brow x>=7, cheeks x>=8, muzzle x>=8 (pushed one voxel forward).
  for (let y = 1; y <= 21; y++) {
    const left = y >= 12 ? 7 : 8;
    for (let x = left; x <= MID / 2; x++)
      for (let z = 2; z <= 10; z++) {
        const edgeX = x === left;
        const edgeZ = z === 2 || z === 10;
        if (edgeX && edgeZ) continue;                       // round the long edges
        if ((y === 1 || y === 21) && (edgeX || edgeZ)) continue;
        sym(x, y, z, y <= 8 ? P.muzzle : P.coat);
      }
  }
  // Muzzle front bulge.
  for (let y = 2; y <= 7; y++)
    for (let x = 9; x <= MID / 2; x++) sym(x, y, 11, P.muzzle);
  // Nostrils.
  for (let y = 4; y <= 5; y++) for (let x = 10; x <= 11; x++) sym(x, y, 11, P.nostril);
  if (opts.grin) for (let x = 11; x <= MID / 2; x++) sym(x, 2, 11, P.mouth);
  // Darker cheek line where muzzle meets face.
  for (let x = 8; x <= MID / 2; x++) sym(x, 9, 10, P.coatDark);
  // Eyes: pale ring, dark 3x3, a highlight towards the middle; they wrap
  // round the side of the head so they read from a three-quarter view too.
  for (let y = 12; y <= 16; y++)
    for (let x = 7; x <= 11; x++) {
      const ring = y === 12 || y === 16 || x === 7 || x === 11;
      sym(x, y, 10, ring ? P.muzzle : P.eye);
    }
  sym(10, 15, 10, P.shine);
  for (let y = 13; y <= 15; y++) for (let z = 7; z <= 9; z++) sym(7, y, z, z === 9 ? P.eye : P.coat);
  // Brow ridge.
  for (let x = 7; x <= MID / 2; x++) if (g.get(x, 17, 10) === P.coat) sym(x, 17, 10, P.coatDark);
  // Forelock: a dark tuft between the ears, falling over the brow.
  for (let y = 18; y <= 25; y++)
    for (let x = 11; x <= MID / 2; x++)
      for (let z = 6; z <= 11; z++) {
        if (y <= 20 && z < 10) continue;         // only the fringe hangs in front
        if (y === 18 && x === 11) continue;      // ragged fringe
        if (y >= 24 && (x === 11 || z > 9)) continue;
        sym(x, y, z, P.mane);
      }
  // Ears: wide, tall, leaning outwards; pale inside, dark tips. Rows 20..36.
  for (let t = 0; t <= 16; t++) {
    const y = 20 + t;
    const shift = -Math.floor(t / 4) * lean;
    const w = t <= 10 ? 6 : t <= 13 ? 5 : t === 14 ? 4 : 2; // tapering tip
    const x1 = 11 + shift;          // inner edge
    const x0 = x1 - w + 1;
    for (let x = x0; x <= x1; x++)
      for (let z = 5; z <= 8; z++) {
        const tip = t >= 13;
        const inner = z === 8 && x > x0 && x < x1 && t >= 1 && !tip;
        sym(x, y, z, tip ? P.tip : inner ? P.ear : P.coat);
      }
  }
  return { grid: g, palette: palette(c) };
}
