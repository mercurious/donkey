// Render Donkey's icon and banner with the VOXEL GT engine's mesher
// (mercurious/voxel-gt-opus, src/voxel.js) and three.js, in headless Chrome.
//   node art/render.mjs [outDir]      -> icon.png (1024x1024), banner.png (1280x640)
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

// The head: grey coat, mouth line, seen almost straight on from a little above.
const HEAD = { coat: 'grey', grin: 1 };
const SHOTS = [
  { id: 'icon', w: 1024, h: 1024, yaw: 0, pitch: 6, fill: 0.93, headX: 0.5 },
  { id: 'banner', w: 1280, h: 640, yaw: -16, pitch: 8, fill: 0.92, headX: 0.76, text: true },
];

const entry = `
import * as THREE from 'three';
import { VoxelGrid, meshGrid } from './src/voxel.js';
import { buildDonkey, SIZE } from ${JSON.stringify(path.join(here, 'donkey.js'))};
const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true });
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
const { grid, palette } = buildDonkey(VoxelGrid, ${JSON.stringify(HEAD)});
const [geo] = meshGrid(grid, palette, { offset: [-SIZE.nx / 2, -SIZE.ny / 2, -SIZE.nz / 2] });
const mesh = new THREE.Mesh(geo, new THREE.MeshLambertMaterial({ vertexColors: true }));
scene.add(mesh);

function round(g, x, y, w, h, r) {
  g.beginPath(); g.moveTo(x + r, y); g.arcTo(x + w, y, x + w, y + h, r); g.arcTo(x + w, y + h, x, y + h, r);
  g.arcTo(x, y + h, x, y, r); g.arcTo(x, y, x + w, y, r); g.closePath();
}

window.render = (v) => {
  const { w, h } = v;
  // The head is rendered square, h x h, then placed on the tile.
  renderer.setSize(h, h);
  mesh.rotation.y = v.yaw * Math.PI / 180;
  const dist = (SIZE.ny / v.fill) / (2 * Math.tan(10 * Math.PI / 180));
  const p = v.pitch * Math.PI / 180;
  camera.position.set(0, Math.sin(p) * dist, Math.cos(p) * dist);
  camera.lookAt(0, 0, 0);
  renderer.render(scene, camera);

  const out = document.createElement('canvas'); out.width = w; out.height = h;
  const g = out.getContext('2d');
  const lg = g.createLinearGradient(0, 0, 0, h); lg.addColorStop(0, '#36e6ff'); lg.addColorStop(1, '#0090b8');
  if (v.text) { g.fillStyle = lg; g.fillRect(0, 0, w, h); }
  else { round(g, 0, 0, w, h, w * 0.223); g.fillStyle = lg; g.fill(); }
  g.save(); g.shadowColor = 'rgba(0,0,0,0.45)'; g.shadowBlur = h * 0.04; g.shadowOffsetY = h * 0.018;
  g.drawImage(renderer.domElement, w * v.headX - h / 2, 0); g.restore();
  if (v.text) {
    const ink = '#04303b', x = w * 0.07;
    g.fillStyle = ink;
    g.font = '800 ' + Math.round(h * 0.25) + 'px "Liberation Sans", "DejaVu Sans", sans-serif';
    g.fillText('Donkey', x, h * 0.47);
    g.font = '700 ' + Math.round(h * 0.068) + 'px "Liberation Sans", "DejaVu Sans", sans-serif';
    g.fillText("Don't have a keyboard?", x, h * 0.62);
    g.globalAlpha = 0.8;
    g.font = '400 ' + Math.round(h * 0.048) + 'px "Liberation Sans", "DejaVu Sans", sans-serif';
    g.fillText('The Firefox web browser for ROCKNIX handhelds', x, h * 0.72);
  }
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
const page = await browser.newPage({ viewport: { width: 1280, height: 1024 } });
page.on('pageerror', (e) => { console.error(e); process.exitCode = 1; });
await page.setContent(html);
await page.waitForFunction('window.ready === true');
for (const v of SHOTS) {
  const url = await page.evaluate((v) => window.render(v), v);
  const file = path.join(outDir, `${v.id}.png`);
  fs.writeFileSync(file, Buffer.from(url.split(',')[1], 'base64'));
  console.log(file);
}
await browser.close();
