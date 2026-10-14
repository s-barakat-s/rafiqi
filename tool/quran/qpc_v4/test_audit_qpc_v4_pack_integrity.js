'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const {
  generateInventory,
  inventoryPayload,
  payloadDigest,
  verifyInventory,
} = require('./audit_qpc_v4_pack_integrity');

const TEST_PAGE_COUNT = 3;

async function makePack() {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'maab-qpc-integrity-'));
  const packDir = path.join(root, 'pack');
  const inventoryPath = path.join(root, 'inventory.json');
  await fs.mkdir(path.join(packDir, 'pages'), { recursive: true });
  await fs.mkdir(path.join(packDir, 'geometry'), { recursive: true });
  let totalImageBytes = 0;
  let totalGeometryBytes = 0;
  for (let page = 1; page <= TEST_PAGE_COUNT; page += 1) {
    const stem = String(page).padStart(3, '0');
    const image = Buffer.from(`synthetic-png-${page}\n`);
    const geometry = Buffer.from(`synthetic-gzip-${page}\n`);
    await fs.writeFile(path.join(packDir, 'pages', `${stem}.png`), image);
    await fs.writeFile(path.join(packDir, 'geometry', `${stem}.json.gz`), geometry);
    totalImageBytes += image.length;
    totalGeometryBytes += geometry.length;
  }
  const manifest = {
    pack_id: 'maab.qpc_v4_tajweed.research.synthetic',
    research_only: true,
    production_approved: false,
    layout: 'phone-native',
    pages_generated: [1, 2, 3],
    page_count: TEST_PAGE_COUNT,
    canonical_width: 1074,
    canonical_height: 1944,
    render_fingerprint: 'synthetic-test-fingerprint',
    total_image_bytes: totalImageBytes,
    total_geometry_bytes: totalGeometryBytes,
    schema_version: 2,
  };
  await fs.writeFile(path.join(packDir, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`);
  return { root, packDir, inventoryPath };
}

function testOptions(context) {
  return {
    packDir: context.packDir,
    inventoryPath: context.inventoryPath,
    expectedPageCount: TEST_PAGE_COUNT,
    allowTestPageCount: true,
  };
}

async function withPack(callback) {
  const context = await makePack();
  try {
    await callback(context);
  } finally {
    await fs.rm(context.root, { recursive: true, force: true });
  }
}

test('generates and verifies a complete synthetic pack', async () => {
  await withPack(async (context) => {
    const generated = await generateInventory(testOptions(context));
    assert.equal(generated.changed, true);
    assert.equal(generated.inventory.pages.length, TEST_PAGE_COUNT);
    await verifyInventory(testOptions(context));
  });
});

test('rejects a missing image', async () => {
  await withPack(async (context) => {
    await fs.rm(path.join(context.packDir, 'pages', '002.png'));
    await assert.rejects(generateInventory(testOptions(context)), /page 2 image: file is missing/);
  });
});

test('rejects missing geometry', async () => {
  await withPack(async (context) => {
    await fs.rm(path.join(context.packDir, 'geometry', '003.json.gz'));
    await assert.rejects(generateInventory(testOptions(context)), /page 3 geometry: file is missing/);
  });
});

test('rejects a duplicate page identity', async () => {
  await withPack(async (context) => {
    await fs.copyFile(path.join(context.packDir, 'pages', '001.png'), path.join(context.packDir, 'pages', '0001.png'));
    await assert.rejects(generateInventory(testOptions(context)), /page 1 image: duplicate page identity/);
  });
});

test('rejects an invalid page number', async () => {
  await withPack(async (context) => {
    await fs.writeFile(path.join(context.packDir, 'pages', '004.png'), 'unexpected');
    await assert.rejects(generateInventory(testOptions(context)), /image: invalid page number in 004\.png/);
  });
});

test('detects same-length image corruption', async () => {
  await withPack(async (context) => {
    await generateInventory(testOptions(context));
    await fs.writeFile(path.join(context.packDir, 'pages', '002.png'), 'XXXXXXXXXXXXXXXX');
    await assert.rejects(verifyInventory(testOptions(context)), /page 2 image: SHA-256 mismatch/);
  });
});

test('detects same-length geometry corruption', async () => {
  await withPack(async (context) => {
    await generateInventory(testOptions(context));
    await fs.writeFile(path.join(context.packDir, 'geometry', '001.json.gz'), 'XXXXXXXXXXXXXXXXX');
    await assert.rejects(verifyInventory(testOptions(context)), /page 1 geometry: SHA-256 mismatch/);
  });
});

test('detects a changed byte length', async () => {
  await withPack(async (context) => {
    await generateInventory(testOptions(context));
    await fs.appendFile(path.join(context.packDir, 'pages', '003.png'), 'extra');
    await assert.rejects(verifyInventory(testOptions(context)), /page 3 image: byte length mismatch/);
  });
});

test('detects an inventory digest mismatch', async () => {
  await withPack(async (context) => {
    await generateInventory(testOptions(context));
    const inventory = JSON.parse(await fs.readFile(context.inventoryPath, 'utf8'));
    inventory.overall_sha256 = '0'.repeat(64);
    await fs.writeFile(context.inventoryPath, `${JSON.stringify(inventory, null, 2)}\n`);
    await assert.rejects(verifyInventory(testOptions(context)), /overall SHA-256 mismatch/);
  });
});

test('generation is deterministic and does not rewrite current output', async () => {
  await withPack(async (context) => {
    const first = await generateInventory(testOptions(context));
    const firstBytes = await fs.readFile(context.inventoryPath);
    const firstStat = await fs.stat(context.inventoryPath);
    const second = await generateInventory(testOptions(context));
    const secondBytes = await fs.readFile(context.inventoryPath);
    const secondStat = await fs.stat(context.inventoryPath);
    assert.equal(first.changed, true);
    assert.equal(second.changed, false);
    assert.deepEqual(secondBytes, firstBytes);
    assert.equal(secondStat.mtimeMs, firstStat.mtimeMs);
  });
});

test('rejects traversal even when the digest is recomputed', async () => {
  await withPack(async (context) => {
    await generateInventory(testOptions(context));
    const inventory = JSON.parse(await fs.readFile(context.inventoryPath, 'utf8'));
    inventory.pages[0].image.path = '../escape.png';
    inventory.overall_sha256 = payloadDigest(inventoryPayload(inventory));
    await fs.writeFile(context.inventoryPath, `${JSON.stringify(inventory, null, 2)}\n`);
    await assert.rejects(verifyInventory(testOptions(context)), /page 1 image: path traversal/);
  });
});
