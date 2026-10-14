#!/usr/bin/env node
'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs');
const fsp = require('node:fs/promises');
const path = require('node:path');

const INVENTORY_SCHEMA_VERSION = 1;
const PRODUCTION_PAGE_COUNT = 604;
const repoRoot = path.resolve(__dirname, '..', '..', '..');
const defaultPackDir = path.join(repoRoot, 'quran_resources', 'qpc_v4_tajweed_pack');
const defaultInventoryPath = path.join(repoRoot, 'quran_resources', 'qpc_v4_tajweed_pack_integrity.json');
const SHA256_PATTERN = /^[0-9a-f]{64}$/;

class IntegrityError extends Error {
  constructor(message) {
    super(message);
    this.name = 'IntegrityError';
  }
}

function requireIntegrity(condition, message) {
  if (!condition) throw new IntegrityError(message);
}

function pageStem(page) {
  return String(page).padStart(3, '0');
}

function inventoryPayload(inventory) {
  return {
    inventory_schema_version: inventory.inventory_schema_version,
    pack_id: inventory.pack_id,
    pack_schema_version: inventory.pack_schema_version,
    render_fingerprint: inventory.render_fingerprint,
    canonical_canvas: inventory.canonical_canvas,
    page_count: inventory.page_count,
    total_image_bytes: inventory.total_image_bytes,
    total_geometry_bytes: inventory.total_geometry_bytes,
    pages: inventory.pages,
  };
}

function serializePayload(payload) {
  return `${JSON.stringify(payload, null, 2)}\n`;
}

function payloadDigest(payload) {
  return crypto.createHash('sha256').update(serializePayload(payload), 'utf8').digest('hex');
}

function serializeInventory(payload) {
  return `${JSON.stringify({ ...payload, overall_sha256: payloadDigest(payload) }, null, 2)}\n`;
}

function effectivePageCount(options = {}) {
  const count = options.expectedPageCount ?? PRODUCTION_PAGE_COUNT;
  requireIntegrity(Number.isInteger(count) && count > 0, 'expected page count must be a positive integer');
  requireIntegrity(
    count === PRODUCTION_PAGE_COUNT || options.allowTestPageCount === true,
    `production integrity operations always require ${PRODUCTION_PAGE_COUNT} pages`,
  );
  return count;
}

async function readJson(file, label) {
  let text;
  try {
    text = await fsp.readFile(file, 'utf8');
  } catch (error) {
    throw new IntegrityError(`${label} is unavailable: ${file} (${error.code ?? error.message})`);
  }
  try {
    return JSON.parse(text);
  } catch (error) {
    throw new IntegrityError(`${label} is not valid JSON: ${file} (${error.message})`);
  }
}

function validateManifest(manifest, expectedPageCount) {
  requireIntegrity(manifest && typeof manifest === 'object' && !Array.isArray(manifest), 'pack manifest must be an object');
  requireIntegrity(typeof manifest.pack_id === 'string' && manifest.pack_id.length > 0, 'pack manifest pack_id is missing');
  requireIntegrity(manifest.research_only === true, 'pack manifest must remain research_only');
  requireIntegrity(manifest.production_approved === false, 'pack manifest must remain production-unapproved');
  requireIntegrity(Number.isInteger(manifest.schema_version) && manifest.schema_version > 0, 'pack manifest schema_version is invalid');
  requireIntegrity(typeof manifest.render_fingerprint === 'string' && manifest.render_fingerprint.length > 0, 'pack manifest render_fingerprint is missing');
  requireIntegrity(manifest.page_count === expectedPageCount, `pack manifest page_count is ${manifest.page_count}; expected ${expectedPageCount}`);
  requireIntegrity(Number.isFinite(manifest.canonical_width) && manifest.canonical_width > 0, 'pack manifest canonical_width is invalid');
  requireIntegrity(Number.isFinite(manifest.canonical_height) && manifest.canonical_height > 0, 'pack manifest canonical_height is invalid');
  requireIntegrity(Array.isArray(manifest.pages_generated), 'pack manifest pages_generated is missing');
  requireIntegrity(manifest.pages_generated.length === expectedPageCount, `pack manifest pages_generated has ${manifest.pages_generated.length} entries; expected ${expectedPageCount}`);
  for (let index = 0; index < expectedPageCount; index += 1) {
    requireIntegrity(manifest.pages_generated[index] === index + 1, `pack manifest pages_generated is invalid at page ${index + 1}`);
  }
}

async function scanCategory(directory, category, expectedPageCount) {
  let entries;
  try {
    entries = await fsp.readdir(directory, { withFileTypes: true });
  } catch (error) {
    throw new IntegrityError(`${category} directory is unavailable: ${directory} (${error.code ?? error.message})`);
  }
  const suffix = category === 'image' ? '.png' : '.json.gz';
  const pattern = category === 'image' ? /^(\d+)\.png$/i : /^(\d+)\.json\.gz$/i;
  const files = new Map();
  for (const entry of entries) {
    requireIntegrity(entry.isFile(), `${category}: unexpected non-file entry ${entry.name}`);
    const match = pattern.exec(entry.name);
    requireIntegrity(match, `${category}: unexpected file ${entry.name}`);
    const page = Number(match[1]);
    requireIntegrity(Number.isInteger(page) && page >= 1 && page <= expectedPageCount, `${category}: invalid page number in ${entry.name}`);
    requireIntegrity(!files.has(page), `page ${page} ${category}: duplicate page identity (${files.get(page)}, ${entry.name})`);
    files.set(page, entry.name);
  }
  for (const [page, name] of files) {
    const expectedName = `${pageStem(page)}${suffix}`;
    requireIntegrity(name === expectedName, `page ${page} ${category}: noncanonical filename ${name}; expected ${expectedName}`);
  }
  for (let page = 1; page <= expectedPageCount; page += 1) {
    requireIntegrity(files.has(page), `page ${page} ${category}: file is missing`);
  }
  requireIntegrity(files.size === expectedPageCount, `${category}: found ${files.size} page files; expected ${expectedPageCount}`);
  return files;
}

async function scanPack(packDir, expectedPageCount) {
  const manifestPath = path.join(packDir, 'manifest.json');
  const manifest = await readJson(manifestPath, 'pack manifest');
  validateManifest(manifest, expectedPageCount);
  const images = await scanCategory(path.join(packDir, 'pages'), 'image', expectedPageCount);
  const geometry = await scanCategory(path.join(packDir, 'geometry'), 'geometry', expectedPageCount);
  return { manifest, images, geometry };
}

async function hashFile(file, page, category) {
  const hash = crypto.createHash('sha256');
  let bytes = 0;
  try {
    await new Promise((resolve, reject) => {
      const stream = fs.createReadStream(file);
      stream.on('data', (chunk) => {
        bytes += chunk.length;
        hash.update(chunk);
      });
      stream.on('error', reject);
      stream.on('end', resolve);
    });
  } catch (error) {
    throw new IntegrityError(`page ${page} ${category}: cannot read ${file} (${error.code ?? error.message})`);
  }
  requireIntegrity(bytes > 0, `page ${page} ${category}: file is empty`);
  return { bytes, sha256: hash.digest('hex') };
}

async function buildPayload(packDir, expectedPageCount) {
  const { manifest, images, geometry } = await scanPack(packDir, expectedPageCount);
  const pages = [];
  let totalImageBytes = 0;
  let totalGeometryBytes = 0;
  for (let page = 1; page <= expectedPageCount; page += 1) {
    const imagePath = `pages/${images.get(page)}`;
    const geometryPath = `geometry/${geometry.get(page)}`;
    const image = await hashFile(path.join(packDir, ...imagePath.split('/')), page, 'image');
    const geometryHash = await hashFile(path.join(packDir, ...geometryPath.split('/')), page, 'geometry');
    totalImageBytes += image.bytes;
    totalGeometryBytes += geometryHash.bytes;
    pages.push({
      page,
      image: { path: imagePath, bytes: image.bytes, sha256: image.sha256 },
      geometry: { path: geometryPath, bytes: geometryHash.bytes, sha256: geometryHash.sha256 },
    });
  }
  requireIntegrity(manifest.total_image_bytes === totalImageBytes, `pack manifest total_image_bytes is ${manifest.total_image_bytes}; actual total is ${totalImageBytes}`);
  requireIntegrity(manifest.total_geometry_bytes === totalGeometryBytes, `pack manifest total_geometry_bytes is ${manifest.total_geometry_bytes}; actual total is ${totalGeometryBytes}`);
  return {
    inventory_schema_version: INVENTORY_SCHEMA_VERSION,
    pack_id: manifest.pack_id,
    pack_schema_version: manifest.schema_version,
    render_fingerprint: manifest.render_fingerprint,
    canonical_canvas: { width: manifest.canonical_width, height: manifest.canonical_height },
    page_count: expectedPageCount,
    total_image_bytes: totalImageBytes,
    total_geometry_bytes: totalGeometryBytes,
    pages,
  };
}

async function atomicWriteIfChanged(destination, content) {
  try {
    if (await fsp.readFile(destination, 'utf8') === content) return false;
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
  await fsp.mkdir(path.dirname(destination), { recursive: true });
  const temporary = `${destination}.tmp-${process.pid}-${crypto.randomBytes(6).toString('hex')}`;
  try {
    await fsp.writeFile(temporary, content, { encoding: 'utf8', flag: 'wx' });
    await fsp.rename(temporary, destination);
  } finally {
    await fsp.rm(temporary, { force: true });
  }
  return true;
}

async function generateInventory(options = {}) {
  const expectedPageCount = effectivePageCount(options);
  const packDir = path.resolve(options.packDir ?? defaultPackDir);
  const inventoryPath = path.resolve(options.inventoryPath ?? defaultInventoryPath);
  const payload = await buildPayload(packDir, expectedPageCount);
  const content = serializeInventory(payload);
  const changed = await atomicWriteIfChanged(inventoryPath, content);
  return { inventory: JSON.parse(content), changed, packDir, inventoryPath };
}

function requireExactKeys(value, expected, label) {
  requireIntegrity(value && typeof value === 'object' && !Array.isArray(value), `${label} must be an object`);
  const actual = Object.keys(value);
  requireIntegrity(actual.length === expected.length && expected.every((key) => actual.includes(key)), `${label} fields are invalid`);
}

function validateAssetPath(assetPath, expectedPath, packDir, page, category) {
  requireIntegrity(typeof assetPath === 'string', `page ${page} ${category}: path must be a string`);
  requireIntegrity(!assetPath.includes('\\'), `page ${page} ${category}: path must use POSIX separators`);
  requireIntegrity(!path.posix.isAbsolute(assetPath) && path.posix.normalize(assetPath) === assetPath, `page ${page} ${category}: path traversal or normalization is not allowed`);
  requireIntegrity(!assetPath.split('/').includes('..'), `page ${page} ${category}: path traversal is not allowed`);
  const resolvedPack = path.resolve(packDir);
  const resolvedAsset = path.resolve(resolvedPack, ...assetPath.split('/'));
  requireIntegrity(resolvedAsset.startsWith(`${resolvedPack}${path.sep}`), `page ${page} ${category}: path escapes the pack`);
  requireIntegrity(assetPath === expectedPath, `page ${page} ${category}: expected path ${expectedPath}, found ${assetPath}`);
  return resolvedAsset;
}

function validateInventoryStructure(inventory, expectedPageCount, packDir) {
  requireExactKeys(inventory, [
    'inventory_schema_version', 'pack_id', 'pack_schema_version', 'render_fingerprint',
    'canonical_canvas', 'page_count', 'total_image_bytes', 'total_geometry_bytes',
    'pages', 'overall_sha256',
  ], 'inventory');
  requireIntegrity(inventory.inventory_schema_version === INVENTORY_SCHEMA_VERSION, `inventory schema version is ${inventory.inventory_schema_version}; expected ${INVENTORY_SCHEMA_VERSION}`);
  requireIntegrity(typeof inventory.pack_id === 'string' && inventory.pack_id.length > 0, 'inventory pack_id is invalid');
  requireIntegrity(Number.isInteger(inventory.pack_schema_version) && inventory.pack_schema_version > 0, 'inventory pack_schema_version is invalid');
  requireIntegrity(typeof inventory.render_fingerprint === 'string' && inventory.render_fingerprint.length > 0, 'inventory render_fingerprint is invalid');
  requireExactKeys(inventory.canonical_canvas, ['width', 'height'], 'inventory canonical_canvas');
  requireIntegrity(Number.isFinite(inventory.canonical_canvas.width) && inventory.canonical_canvas.width > 0, 'inventory canonical canvas width is invalid');
  requireIntegrity(Number.isFinite(inventory.canonical_canvas.height) && inventory.canonical_canvas.height > 0, 'inventory canonical canvas height is invalid');
  requireIntegrity(inventory.page_count === expectedPageCount, `inventory page_count is ${inventory.page_count}; expected ${expectedPageCount}`);
  requireIntegrity(Number.isSafeInteger(inventory.total_image_bytes) && inventory.total_image_bytes >= 0, 'inventory total_image_bytes is invalid');
  requireIntegrity(Number.isSafeInteger(inventory.total_geometry_bytes) && inventory.total_geometry_bytes >= 0, 'inventory total_geometry_bytes is invalid');
  requireIntegrity(Array.isArray(inventory.pages) && inventory.pages.length === expectedPageCount, `inventory pages has ${inventory.pages?.length ?? 'invalid'} entries; expected ${expectedPageCount}`);
  const paths = [];
  for (let index = 0; index < expectedPageCount; index += 1) {
    const expectedPage = index + 1;
    const entry = inventory.pages[index];
    requireExactKeys(entry, ['page', 'image', 'geometry'], `page ${expectedPage} inventory entry`);
    requireIntegrity(entry.page === expectedPage, `inventory page order/identity is invalid at position ${expectedPage}`);
    for (const category of ['image', 'geometry']) {
      const asset = entry[category];
      requireExactKeys(asset, ['path', 'bytes', 'sha256'], `page ${expectedPage} ${category}`);
      const expectedPath = category === 'image'
        ? `pages/${pageStem(expectedPage)}.png`
        : `geometry/${pageStem(expectedPage)}.json.gz`;
      const resolved = validateAssetPath(asset.path, expectedPath, packDir, expectedPage, category);
      requireIntegrity(Number.isSafeInteger(asset.bytes) && asset.bytes > 0, `page ${expectedPage} ${category}: byte length is invalid`);
      requireIntegrity(typeof asset.sha256 === 'string' && SHA256_PATTERN.test(asset.sha256), `page ${expectedPage} ${category}: SHA-256 is invalid`);
      paths.push(resolved);
    }
  }
  requireIntegrity(new Set(paths).size === paths.length, 'inventory contains duplicate asset paths');
  requireIntegrity(typeof inventory.overall_sha256 === 'string' && SHA256_PATTERN.test(inventory.overall_sha256), 'inventory overall_sha256 is invalid');
}

async function verifyInventory(options = {}) {
  const expectedPageCount = effectivePageCount(options);
  const packDir = path.resolve(options.packDir ?? defaultPackDir);
  const inventoryPath = path.resolve(options.inventoryPath ?? defaultInventoryPath);
  const inventory = await readJson(inventoryPath, 'integrity inventory');
  validateInventoryStructure(inventory, expectedPageCount, packDir);
  const { manifest } = await scanPack(packDir, expectedPageCount);
  requireIntegrity(inventory.pack_id === manifest.pack_id, 'inventory pack_id differs from the current manifest');
  requireIntegrity(inventory.pack_schema_version === manifest.schema_version, 'inventory pack_schema_version differs from the current manifest');
  requireIntegrity(inventory.render_fingerprint === manifest.render_fingerprint, 'inventory render_fingerprint differs from the current manifest');
  requireIntegrity(inventory.canonical_canvas.width === manifest.canonical_width && inventory.canonical_canvas.height === manifest.canonical_height, 'inventory canonical_canvas differs from the current manifest');
  let totalImageBytes = 0;
  let totalGeometryBytes = 0;
  for (const entry of inventory.pages) {
    for (const category of ['image', 'geometry']) {
      const asset = entry[category];
      const file = path.resolve(packDir, ...asset.path.split('/'));
      const actual = await hashFile(file, entry.page, category);
      requireIntegrity(actual.bytes === asset.bytes, `page ${entry.page} ${category}: byte length mismatch (inventory ${asset.bytes}, actual ${actual.bytes})`);
      requireIntegrity(actual.sha256 === asset.sha256, `page ${entry.page} ${category}: SHA-256 mismatch`);
      if (category === 'image') totalImageBytes += actual.bytes;
      else totalGeometryBytes += actual.bytes;
    }
  }
  requireIntegrity(totalImageBytes === inventory.total_image_bytes, `inventory total_image_bytes is ${inventory.total_image_bytes}; actual total is ${totalImageBytes}`);
  requireIntegrity(totalGeometryBytes === inventory.total_geometry_bytes, `inventory total_geometry_bytes is ${inventory.total_geometry_bytes}; actual total is ${totalGeometryBytes}`);
  requireIntegrity(manifest.total_image_bytes === totalImageBytes, 'current manifest total_image_bytes differs from verified files');
  requireIntegrity(manifest.total_geometry_bytes === totalGeometryBytes, 'current manifest total_geometry_bytes differs from verified files');
  const expectedDigest = payloadDigest(inventoryPayload(inventory));
  requireIntegrity(inventory.overall_sha256 === expectedDigest, `inventory overall SHA-256 mismatch (stored ${inventory.overall_sha256}, calculated ${expectedDigest})`);
  return { inventory, packDir, inventoryPath };
}

function parseArguments(argv) {
  const options = {};
  let mode = null;
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === 'generate' || argument === 'verify') {
      requireIntegrity(mode === null, 'specify exactly one mode: generate or verify');
      mode = argument;
    } else if (argument === '--pack') {
      requireIntegrity(index + 1 < argv.length, '--pack requires a directory');
      options.packDir = argv[++index];
    } else if (argument === '--inventory') {
      requireIntegrity(index + 1 < argv.length, '--inventory requires a file path');
      options.inventoryPath = argv[++index];
    } else if (argument === '--test-page-count') {
      requireIntegrity(process.env.MAAB_QPC_INTEGRITY_TEST_ONLY === '1', '--test-page-count is available only when MAAB_QPC_INTEGRITY_TEST_ONLY=1');
      requireIntegrity(index + 1 < argv.length, '--test-page-count requires a value');
      options.expectedPageCount = Number(argv[++index]);
      options.allowTestPageCount = true;
    } else if (argument === '--help' || argument === '-h') {
      return { help: true };
    } else {
      throw new IntegrityError(`unknown argument: ${argument}`);
    }
  }
  requireIntegrity(mode !== null, 'specify a mode: generate or verify');
  return { mode, options };
}

function usage() {
  return [
    'Usage:',
    '  node tool/quran/qpc_v4/audit_qpc_v4_pack_integrity.js generate [--pack DIR] [--inventory FILE]',
    '  node tool/quran/qpc_v4/audit_qpc_v4_pack_integrity.js verify   [--pack DIR] [--inventory FILE]',
    '',
    `Production operations always require exactly ${PRODUCTION_PAGE_COUNT} page pairs.`,
  ].join('\n');
}

async function main() {
  const parsed = parseArguments(process.argv.slice(2));
  if (parsed.help) {
    console.log(usage());
    return;
  }
  const result = parsed.mode === 'generate'
    ? await generateInventory(parsed.options)
    : await verifyInventory(parsed.options);
  const action = parsed.mode === 'generate'
    ? (result.changed ? 'generated' : 'already current')
    : 'verified';
  console.log(`QPC V4 integrity inventory ${action}: ${result.inventory.page_count} page pairs`);
  console.log(`Images: ${result.inventory.total_image_bytes} bytes`);
  console.log(`Geometry: ${result.inventory.total_geometry_bytes} bytes`);
  console.log(`Overall SHA-256: ${result.inventory.overall_sha256}`);
  console.log(`Inventory: ${result.inventoryPath}`);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`QPC V4 integrity inventory failed: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  IntegrityError,
  generateInventory,
  inventoryPayload,
  payloadDigest,
  serializeInventory,
  verifyInventory,
};
