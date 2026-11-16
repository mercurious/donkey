// Render Donkey's icon variations with the VOXEL GT engine's mesher
// (mercurious/voxel-gt-opus, src/voxel.js) and three.js, in headless Chrome.
//   node art/render.mjs [outDir]
// Env: VOXEL_GT   path to a voxel-gt-opus checkout (default ~/voxel/gt-opus;
//                 needs its node_modules: three, esbuild, playwright-core)
//      CHROME     Chrome/Chromium binary (default playwright's chromium-1140)
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const engine = process.env.VOXEL_GT || path.join(os.homedir(), 'voxel/gt-opus');
const outDir = process.argv[2] || path.join(here, '..', 'build', 'art');
fs.mkdirSync(outDir, { recursive: true });
const req = createRequire(path.join(engine, 'package.json'));
const { build } = req('esbuild');
const { chromium } = req('playwright-core');

// Each variant: coat, camera yaw/pitch (degrees), tile style, and how much
// of the tile's height the head fills.
const VARIANTS = [
  { id: 'a-front-night', coat: 'grey', yaw: 0, pitch: 8, tile: 'night', fill: 0.86 },
  { id: 'b-keycap', coat: 'grey', yaw: 0, pitch: 8, tile: 'keycap', fill: 0.7 },
  { id: 'c-brown-turn', coat: 'brown', yaw: 26, pitch: 10, tile: 'dusk', fill: 0.86 },
  { id: 'd-cyan-close', coat: 'grey', yaw: 0, pitch: 6, tile: 'cyan', fill: 0.93, grin: 1 },
];

const entry = `
import * as THREE from 'three';
import { VoxelGrid, meshGrid } from './src/voxel.js';
import { buildDonkey, SIZE } from ${JSON.stringify(path.join(here, 'donkey.js'))};
const S = 1024;
const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true });
renderer.setSize(S, S);
renderer.setClearColor(0x000000, 0);
renderer.outputColorSpace = THREE.SRGBColorSpace;
const scene = new THREE.Scene();
const hemi = new THREE.HemisphereLight('#f2f4ff', '#3a3440', 1.5);
const key = new THREE.DirectionalLight('#fff4e6', 2.2);
key.position.set(-4, 7, 9);
const rim = new THREE.DirectionalLight('#00ddff', 1.6);
rim.position.set(7, 4, -6);
scene.add(hemi, key, rim);
const camera = new THREE.PerspectiveCamera(20, 1, 1, 400);
let mesh = null;

const TILES = {
  night: (g) => grad(g, '#2b2a33', '#0f0e14'),
  dusk: (g) => grad(g, '#3a2a4a', '#120d18'),
  cyan: (g) => grad(g, '#36e6ff', '#0090b8'),
  keycap: (g) => {
    grad(g, '#1c1b22', '#0c0b10');
    // a keyboard key with Donkey's cyan focus ring around it
    round(g, 84, 84, S - 168, S - 168, 150); g.fillStyle = '#2b2a33'; g.fill();
    g.lineWidth = 34; g.strokeStyle = '#00ddff'; g.stroke();
  },
};
function round(g, x, y, w, h, r) {
  g.beginPath(); g.moveTo(x + r, y); g.arcTo(x + w, y, x + w, y + h, r); g.arcTo(x + w, y + h, x, y + h, r);
  g.arcTo(x, y + h, x, y, r); g.arcTo(x, y, x + w, y, r); g.closePath();
}
function grad(g, top, bottom) {
  const lg = g.createLinearGradient(0, 0, 0, S); lg.addColorStop(0, top); lg.addColorStop(1, bottom);
  round(g, 0, 0, S, S, 228); g.fillStyle = lg; g.fill();
}

window.render = (v) => {
  if (mesh) { scene.remove(mesh); mesh.geometry.dispose(); }
  const { grid, palette } = buildDonkey(VoxelGrid, v);
  const [geo] = meshGrid(grid, palette, { offset: [-SIZE.nx / 2, -SIZE.ny / 2, -SIZE.nz / 2] });
  mesh = new THREE.Mesh(geo, new THREE.MeshLambertMaterial({ vertexColors: true }));
  mesh.rotation.y = (v.yaw || 0) * Math.PI / 180;
  scene.add(mesh);
  const fill = v.fill;
  const dist = (SIZE.ny / fill) / (2 * Math.tan(10 * Math.PI / 180));
  const p = (v.pitch || 0) * Math.PI / 180;
  camera.position.set(0, Math.sin(p) * dist, Math.cos(p) * dist);
  camera.lookAt(0, 0, 0);
  renderer.render(scene, camera);
  const out = document.createElement('canvas'); out.width = out.height = S;
  const g = out.getContext('2d');
  g.save(); TILES[v.tile](g); g.restore();
  // soft shadow under the head, then the head
  g.save(); g.shadowColor = 'rgba(0,0,0,0.45)'; g.shadowBlur = 40; g.shadowOffsetY = 18;
  g.drawImage(renderer.domElement, 0, v.tile === 'keycap' ? 10 : 0); g.restore();
  return out.toDataURL('image/png');
};
window.ready = true;
`;

const bundle = await build({
  stdin: { contents: entry, resolveDir: engine, loader: 'js' },
  bundle: true, format: 'iife', write: false, target: 'es2020', logLevel: 'error',
});
const html = `<!doctype html><html><body style="margin:0;background:#000"><script>${bundle.outputFiles[0].text.replace(/<\/script/gi, '<\\/script')}</script></body></html>`;
const exe = process.env.CHROME || path.join(os.homedir(), '.cache/ms-playwright/chromium-1140/chrome-linux/chrome');
const browser = await chromium.launch({ executablePath: exe, args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1024, height: 1024 } });
page.on('pageerror', (e) => { console.error(e); process.exitCode = 1; });
await page.setContent(html);
await page.waitForFunction('window.ready === true');
for (const v of VARIANTS) {
  const url = await page.evaluate((v) => window.render(v), v);
  const file = path.join(outDir, `${v.id}.png`);
  fs.writeFileSync(file, Buffer.from(url.split(',')[1], 'base64'));
  console.log(file);
}
await browser.close();
