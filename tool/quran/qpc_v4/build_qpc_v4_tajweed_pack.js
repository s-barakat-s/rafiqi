#!/usr/bin/env node
'use strict';

// Research-only, dependency-free QPC V4 Tajweed pack builder.
const childProcess = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const { pathToFileURL } = require('url');

const VERSION = '2.3.0';
const SCHEMA = 2;
const STABLE_RENDER_FINGERPRINT = 'qpc-v4-tajweed-transparent-content-no-heading-frame-v4-indexed-png256';
const PHONE_NATIVE_RENDER_FINGERPRINT = 'qpc-v4-tajweed-phone-native-1074x1944-generated-specials-v8-indexed-png256';
const PAGE_COUNT = 604;
const PHONE_NATIVE_LAYOUT = Object.freeze({
  name: 'phone-native',
  width: 1074,
  height: 1944,
  targetContentTop: 72,
  targetContentBottom: 1872,
  horizontalPadding: 28,
  distributionTolerance: 1,
  fingerprint: PHONE_NATIVE_RENDER_FINGERPRINT,
});
const PHONE_NATIVE_OPENING_PAGE_LAYOUT = Object.freeze({
  version: 'tight-centered-v1',
  lineGap: 40,
});
const PHONE_NATIVE_TERMINAL_HEADING_LAYOUT = 'terminal-top-compensation-v1';
let activeLayout = null;
let RENDER_FINGERPRINT = STABLE_RENDER_FINGERPRINT;
let WIDTH = 1200;
let HEIGHT = 1800;
const SCALE = 1;
const FONT_SIZE = 57;
const BROWSER_TIMEOUT_MS = 30000;
const REPOSITORY = 'https://github.com/hussainsajib/qpc-v4-mushaf-bundle';
const COMMIT = 'f84ccb5688d5404748a0d38e6c53e09df4469ec9';
const ARCHIVE_URL = `${REPOSITORY}/archive/${COMMIT}.zip`;

const repoRoot = path.resolve(__dirname, '..', '..', '..');
const surahHeaderLightAsset = path.join(repoRoot, 'assets', 'image', 'quran', 'mushaf', 'surah_header_light.png');
const medallionMetadataFontAsset = path.join(repoRoot, 'assets', 'fonts', 'Amiri', 'Amiri-Bold.ttf');
const resourceRoot = path.join(repoRoot, 'quran_resources');
const spikeRoot = path.join(resourceRoot, '.cache', 'qpc_v4_tajweed_spike');
const sourceRoot = path.join(resourceRoot, '.cache', 'qpc_v4_source', COMMIT);
let packRoot = path.join(resourceRoot, 'qpc_v4_tajweed_pack');
let pagesRoot = path.join(packRoot, 'pages');
let geometryRoot = path.join(packRoot, 'geometry');
let licensesRoot = path.join(packRoot, 'licenses');
const workRoot = path.join(sourceRoot, '_work');
const sourceArchive = path.join(sourceRoot, 'source.zip');
const sourceCacheManifest = path.join(sourceRoot, 'source-cache.json');

class InvariantError extends Error {
  constructor(message) { super(message); this.name = 'InvariantError'; }
}

class BrowserProcessError extends Error {
  constructor(message) { super(message); this.name = 'BrowserProcessError'; }
}

function requireInvariant(condition, message) {
  if (!condition) throw new InvariantError(message);
}

function ensureDirectory(directory) { fs.mkdirSync(directory, { recursive: true }); }
function nonEmptyFile(file) { return fs.existsSync(file) && fs.statSync(file).isFile() && fs.statSync(file).size > 0; }
function pngDimensions(file) {
  requireInvariant(nonEmptyFile(file), `required PNG asset is missing or empty: ${file}`);
  const png = fs.readFileSync(file);
  requireInvariant(
    png.length >= 24 && png.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])),
    `required asset is not a complete PNG: ${file}`,
  );
  return { width: png.readUInt32BE(16), height: png.readUInt32BE(20) };
}
function stem(page) { return String(page).padStart(3, '0'); }
function arabicNumber(value) { return String(value).replace(/\d/g, (digit) => '٠١٢٣٤٥٦٧٨٩'[Number(digit)]); }
function finite(value) { return typeof value === 'number' && Number.isFinite(value); }
function round2(value) { return Math.round(value * 100) / 100; }
function html(value) {
  return String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
}

function sourcePath(relative) { return path.join(sourceRoot, ...relative.split('/')); }
function usesPhoneNativeOpeningPageLayout(page) {
  return Boolean(activeLayout) && (page === 1 || page === 2);
}
function hasTerminalSurahHeading(lines) {
  return lines.length > 0 && lines[lines.length - 1].type === 'surah_name';
}

function configureLayout(layout) {
  activeLayout = layout === PHONE_NATIVE_LAYOUT.name ? PHONE_NATIVE_LAYOUT : null;
  WIDTH = activeLayout?.width ?? 1200;
  HEIGHT = activeLayout?.height ?? 1800;
  RENDER_FINGERPRINT = activeLayout?.fingerprint ?? STABLE_RENDER_FINGERPRINT;
  packRoot = path.join(resourceRoot, 'qpc_v4_tajweed_pack');
  pagesRoot = path.join(packRoot, 'pages');
  geometryRoot = path.join(packRoot, 'geometry');
  licensesRoot = path.join(packRoot, 'licenses');
}

function sha256(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }

function requiredSourceFiles() {
  const files = [
    'data/words.csv', 'data/page_lines.csv', 'data/qpc_mapping.csv',
    'fonts/surah-name-v4.woff2', 'fonts/QCF4_Hafs_01_W.woff2', 'LICENSE-NOTICE.md',
  ];
  for (let page = 1; page <= PAGE_COUNT; page += 1) files.push(`fonts/qpcv4/p${page}.woff2`);
  return files;
}

function validateSourceCache() {
  if (!nonEmptyFile(sourceCacheManifest)) return false;
  let manifest;
  try { manifest = JSON.parse(fs.readFileSync(sourceCacheManifest, 'utf8')); } catch (_) { return false; }
  if (manifest.repository !== REPOSITORY || manifest.commit !== COMMIT || !Array.isArray(manifest.files)) return false;
  const expected = requiredSourceFiles();
  if (manifest.files.length !== expected.length) return false;
  const recorded = new Map(manifest.files.map((entry) => [entry.path, entry]));
  for (const relative of expected) {
    const entry = recorded.get(relative), file = sourcePath(relative);
    if (!entry || !nonEmptyFile(file)) return false;
    const bytes = fs.readFileSync(file);
    if (bytes.length !== entry.bytes || sha256(bytes) !== entry.sha256) return false;
  }
  return true;
}

function findZipDirectory(zip) {
  const signature = 0x06054b50;
  for (let offset = zip.length - 22; offset >= Math.max(0, zip.length - 65557); offset -= 1) {
    if (zip.readUInt32LE(offset) === signature) {
      return { entries: zip.readUInt16LE(offset + 10), offset: zip.readUInt32LE(offset + 16) };
    }
  }
  throw new InvariantError('pinned source ZIP directory was not found');
}

function archiveRelativePath(entryName) {
  const normalized = entryName.replaceAll('\\', '/');
  const firstSlash = normalized.indexOf('/');
  return firstSlash < 0 ? normalized : normalized.slice(firstSlash + 1);
}

function extractPinnedArchive() {
  const wanted = new Set(requiredSourceFiles());
  const zip = fs.readFileSync(sourceArchive);
  const directory = findZipDirectory(zip);
  let cursor = directory.offset;
  for (let index = 0; index < directory.entries; index += 1) {
    requireInvariant(zip.readUInt32LE(cursor) === 0x02014b50, `invalid pinned ZIP entry ${index}`);
    const method = zip.readUInt16LE(cursor + 10);
    const compressedBytes = zip.readUInt32LE(cursor + 20);
    const originalBytes = zip.readUInt32LE(cursor + 24);
    const nameBytes = zip.readUInt16LE(cursor + 28);
    const extraBytes = zip.readUInt16LE(cursor + 30);
    const commentBytes = zip.readUInt16LE(cursor + 32);
    const localOffset = zip.readUInt32LE(cursor + 42);
    const name = zip.subarray(cursor + 46, cursor + 46 + nameBytes).toString('utf8');
    const relative = archiveRelativePath(name);
    if (wanted.has(relative)) {
      requireInvariant(method === 0 || method === 8, `unsupported ZIP compression for ${relative}`);
      requireInvariant(zip.readUInt32LE(localOffset) === 0x04034b50, `invalid ZIP local header for ${relative}`);
      const localNameBytes = zip.readUInt16LE(localOffset + 26);
      const localExtraBytes = zip.readUInt16LE(localOffset + 28);
      const start = localOffset + 30 + localNameBytes + localExtraBytes;
      const compressed = zip.subarray(start, start + compressedBytes);
      const bytes = method === 0 ? Buffer.from(compressed) : zlib.inflateRawSync(compressed);
      requireInvariant(bytes.length === originalBytes && bytes.length > 0, `invalid extracted size for ${relative}`);
      const destination = sourcePath(relative);
      ensureDirectory(path.dirname(destination));
      const temporary = `${destination}.partial`;
      fs.writeFileSync(temporary, bytes);
      fs.renameSync(temporary, destination);
      wanted.delete(relative);
    }
    cursor += 46 + nameBytes + extraBytes + commentBytes;
  }
  requireInvariant(wanted.size === 0, `pinned archive lacks required files: ${[...wanted].slice(0, 5).join(', ')}`);
}

function writeSourceCacheManifest() {
  const files = requiredSourceFiles().map((relative) => {
    const bytes = fs.readFileSync(sourcePath(relative));
    return { path: relative, bytes: bytes.length, sha256: sha256(bytes) };
  });
  const manifest = {
    schema_version: 1,
    repository: REPOSITORY,
    commit: COMMIT,
    archive_url: ARCHIVE_URL,
    archive_sha256: sha256(fs.readFileSync(sourceArchive)),
    files,
  };
  const temporary = `${sourceCacheManifest}.partial`;
  fs.writeFileSync(temporary, `${JSON.stringify(manifest, null, 2)}\n`);
  fs.rmSync(sourceCacheManifest, { force: true });
  fs.renameSync(temporary, sourceCacheManifest);
}

async function ensurePinnedSourceCache() {
  if (validateSourceCache()) return;
  ensureDirectory(sourceRoot);
  if (!nonEmptyFile(sourceArchive)) {
    const response = await fetch(ARCHIVE_URL, { redirect: 'follow', headers: { 'User-Agent': 'maab-qpc-v4-research-builder' } });
    requireInvariant(response.ok, `pinned source archive fetch failed (${response.status})`);
    const bytes = Buffer.from(await response.arrayBuffer());
    requireInvariant(bytes.length > 0, 'pinned source archive was empty');
    const temporary = `${sourceArchive}.partial`;
    fs.writeFileSync(temporary, bytes);
    fs.renameSync(temporary, sourceArchive);
  }
  extractPinnedArchive();
  writeSourceCacheManifest();
  requireInvariant(validateSourceCache(), 'pinned local source cache failed integrity validation');
}

function parseCsv(text) {
  const rows = [];
  let row = [], field = '', quoted = false;
  for (let index = 0; index < text.length; index += 1) {
    const character = text[index];
    if (quoted) {
      if (character === '"' && text[index + 1] === '"') { field += '"'; index += 1; }
      else if (character === '"') quoted = false;
      else field += character;
    } else if (character === '"') quoted = true;
    else if (character === ',') { row.push(field); field = ''; }
    else if (character === '\n') { row.push(field.replace(/\r$/, '')); rows.push(row); row = []; field = ''; }
    else field += character;
  }
  if (field || row.length) { row.push(field.replace(/\r$/, '')); rows.push(row); }
  requireInvariant(rows.length > 1, 'CSV contains no data rows');
  const headers = rows.shift().map((value) => value.trim());
  return rows.filter((values) => values.some(Boolean)).map((values) =>
    Object.fromEntries(headers.map((header, index) => [header, values[index] ?? ''])));
}

function locateChrome() {
  const candidates = [
    process.env.MAAB_QPC_CHROME,
    process.platform === 'win32' ? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe' : null,
    process.platform === 'win32' ? 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe' : null,
    process.platform === 'darwin' ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' : null,
    process.platform === 'linux' ? '/usr/bin/google-chrome' : null,
    process.platform === 'linux' ? '/usr/bin/chromium' : null,
  ].filter(Boolean);
  const browser = candidates.find((candidate) => fs.existsSync(candidate));
  requireInvariant(browser, 'Chrome/Chromium not found; set MAAB_QPC_CHROME to its absolute executable path');
  return browser;
}

function parseArguments(argv) {
  let from = 1, to = PAGE_COUNT;
  let pageMode = false, rangeMode = false, pagesMode = false, explicitPages = null;
  let layout = null;
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === '--layout') {
      requireInvariant(layout === null, '--layout cannot be repeated');
      requireInvariant(index + 1 < argv.length, '--layout requires a value');
      layout = argv[++index];
      requireInvariant(layout === PHONE_NATIVE_LAYOUT.name, `unsupported --layout value: ${layout}`);
    } else if (argument === '--page') {
      requireInvariant(!rangeMode && !pageMode && !pagesMode, '--page cannot be combined with another page selector or repeated');
      requireInvariant(index + 1 < argv.length, '--page requires a value');
      pageMode = true;
      from = to = Number(argv[++index]);
    } else if (argument === '--pages') {
      requireInvariant(!rangeMode && !pageMode && !pagesMode, '--pages cannot be combined with another page selector or repeated');
      requireInvariant(index + 1 < argv.length, '--pages requires a comma-separated value');
      pagesMode = true;
      explicitPages = argv[++index].split(',').map((value) => Number(value.trim()));
      requireInvariant(explicitPages.length > 0 && explicitPages.every((page) => Number.isInteger(page) && page >= 1 && page <= PAGE_COUNT),
        `invalid --pages value; expected comma-separated pages in 1..${PAGE_COUNT}`);
      requireInvariant(new Set(explicitPages).size === explicitPages.length, '--pages contains duplicate page numbers');
    } else if (argument === '--from') {
      requireInvariant(!pageMode && !pagesMode, '--from cannot be combined with --page/--pages');
      requireInvariant(index + 1 < argv.length, '--from requires a value');
      rangeMode = true;
      from = Number(argv[++index]);
    } else if (argument === '--to') {
      requireInvariant(!pageMode && !pagesMode, '--to cannot be combined with --page/--pages');
      requireInvariant(index + 1 < argv.length, '--to requires a value');
      rangeMode = true;
      to = Number(argv[++index]);
    } else {
      throw new InvariantError(`unknown argument: ${argument}`);
    }
  }
  requireInvariant(Number.isInteger(from) && Number.isInteger(to) && from >= 1 && to <= PAGE_COUNT && from <= to,
    `invalid page range ${from}..${to}; expected 1..${PAGE_COUNT}`);
  const pages = explicitPages ?? Array.from({ length: to - from + 1 }, (_, index) => from + index);
  return { layout, pages };
}

function loadSource() {
  const wordRows = parseCsv(fs.readFileSync(sourcePath('data/words.csv'), 'utf8'));
  const lineRows = parseCsv(fs.readFileSync(sourcePath('data/page_lines.csv'), 'utf8'));
  const mappingRows = parseCsv(fs.readFileSync(sourcePath('data/qpc_mapping.csv'), 'utf8'));
  const words = new Map(), mappings = new Map(), pages = new Map(), validAyahs = new Set();

  for (const row of wordRows) {
    const word = { id: Number(row.id), location: row.location, surah: Number(row.surah), ayah: Number(row.ayah), position: Number(row.word), text: row.text };
    requireInvariant(Number.isInteger(word.id) && word.id > 0, `invalid source word id ${row.id}`);
    requireInvariant(Number.isInteger(word.surah) && word.surah >= 1 && word.surah <= 114, `invalid Surah for word ${word.id}`);
    requireInvariant(Number.isInteger(word.ayah) && word.ayah >= 1, `invalid Ayah for word ${word.id}`);
    requireInvariant(Number.isInteger(word.position) && word.position >= 1, `invalid position for word ${word.id}`);
    requireInvariant(!words.has(word.id), `duplicate source word id ${word.id}`);
    words.set(word.id, word);
    validAyahs.add(`${word.surah}:${word.ayah}`);
  }
  for (const row of mappingRows) {
    const id = Number(row.word_id), page = Number(row.page_number);
    const codepoints = row.code.trim().split(/\s+/).filter(Boolean).map(Number);
    requireInvariant(Number.isInteger(id) && id > 0 && !mappings.has(id), `invalid/duplicate mapping id ${row.word_id}`);
    requireInvariant(Number.isInteger(page) && page >= 1 && page <= PAGE_COUNT, `invalid mapping page for word ${id}`);
    requireInvariant(codepoints.length > 0 && codepoints.every((value) => Number.isInteger(value) && value > 0), `invalid glyph mapping for word ${id}`);
    mappings.set(id, { page, codepoints });
  }
  for (const row of lineRows) {
    const page = Number(row.page_number), line = Number(row.line_number);
    requireInvariant(Number.isInteger(page) && page >= 1 && page <= PAGE_COUNT, `invalid source page ${row.page_number}`);
    requireInvariant(Number.isInteger(line) && line >= 1 && line <= 15, `invalid line ${row.line_number} on page ${page}`);
    if (!pages.has(page)) pages.set(page, []);
    pages.get(page).push({
      page, line, type: row.line_type, centered: /^(1|true|yes)$/i.test(row.is_centered),
      first: row.first_word_id ? Number(row.first_word_id) : null,
      last: row.last_word_id ? Number(row.last_word_id) : null,
      surah: row.surah_number ? Number(row.surah_number) : null,
    });
  }
  requireInvariant(pages.size === PAGE_COUNT, `source has ${pages.size} pages, expected ${PAGE_COUNT}`);
  for (let page = 1; page <= PAGE_COUNT; page += 1) {
    const lines = pages.get(page);
    requireInvariant(lines && lines.length, `source page ${page} is missing`);
    lines.sort((a, b) => a.line - b.line);
    requireInvariant(new Set(lines.map((line) => line.line)).size === lines.length, `duplicate line on page ${page}`);
  }
  return { words, mappings, pages, validAyahs };
}

function isMarker(text) { return /^\p{Nd}+$/u.test(text.trim()); }

function prepare(source) {
  const pages = new Map(), globalWordKeys = new Set();
  for (let page = 1; page <= PAGE_COUNT; page += 1) {
    const lines = source.pages.get(page).map((line) => {
      requireInvariant(['ayah', 'surah_name', 'basmallah'].includes(line.type), `unknown line type '${line.type}' on page ${page}`);
      if (line.type === 'surah_name') {
        requireInvariant(Number.isInteger(line.surah) && line.surah >= 1 && line.surah <= 114, `invalid surah heading on page ${page}`);
        return { ...line, items: [] };
      }
      if (line.type === 'basmallah') return { ...line, items: [] };
      requireInvariant(Number.isInteger(line.first) && Number.isInteger(line.last) && line.first <= line.last, `invalid word range on page ${page}, line ${line.line}`);
      const items = [];
      for (let id = line.first; id <= line.last; id += 1) {
        const word = source.words.get(id), mapping = source.mappings.get(id);
        requireInvariant(word && mapping, `missing word/mapping ${id} on page ${page}`);
        requireInvariant(mapping.page === page, `mapping ${id} points to page ${mapping.page}, expected ${page}`);
        const marker = isMarker(word.text);
        const wordKey = marker ? null : `${word.surah}:${word.ayah}:${word.position}`;
        if (wordKey) {
          requireInvariant(!globalWordKeys.has(wordKey), `duplicate WordKey ${wordKey}`);
          globalWordKeys.add(wordKey);
        }
        items.push({ ...word, classification: marker ? 'ayah_marker' : 'quran_word', wordKey, glyph: String.fromCodePoint(...mapping.codepoints) });
      }
      requireInvariant(items.length > 0, `empty Ayah line on page ${page}, line ${line.line}`);
      return { ...line, items };
    });
    pages.set(page, lines);
  }
  return { pages, quranWordCount: globalWordKeys.size };
}

function phoneNativeTransformScript(page, headingLayoutCompensation) {
  if (!activeLayout) return '';
  const openingPageLayout = usesPhoneNativeOpeningPageLayout(page);
  const distributionValidation = openingPageLayout
    ? `const finalCenter=(finalTop+finalBottom)/2;
if(finalTop<${PHONE_NATIVE_LAYOUT.targetContentTop}-${PHONE_NATIVE_LAYOUT.distributionTolerance}||finalBottom>${PHONE_NATIVE_LAYOUT.targetContentBottom}+${PHONE_NATIVE_LAYOUT.distributionTolerance}||Math.abs(finalCenter-${(PHONE_NATIVE_LAYOUT.targetContentTop + PHONE_NATIVE_LAYOUT.targetContentBottom) / 2})>${PHONE_NATIVE_LAYOUT.distributionTolerance})throw new Error('phone-native opening-page content is not centered in the target area');`
    : `if(Math.abs(finalTop-${PHONE_NATIVE_LAYOUT.targetContentTop})>${PHONE_NATIVE_LAYOUT.distributionTolerance}||Math.abs(finalBottom-${PHONE_NATIVE_LAYOUT.targetContentBottom})>${PHONE_NATIVE_LAYOUT.distributionTolerance})throw new Error('phone-native content distribution did not reach the target bounds');`;
  const gapValidation = openingPageLayout
    ? `const gap=block.y-(previous.y+previous.height),expectedGap=previous.type==='surah_heading'?${round2(PHONE_NATIVE_OPENING_PAGE_LAYOUT.lineGap - headingLayoutCompensation)}:${PHONE_NATIVE_OPENING_PAGE_LAYOUT.lineGap};if(Math.abs(gap-expectedGap)>.05)throw new Error('phone-native opening-page line gap mismatch at lines '+previous.line+' and '+block.line);`
    : '';
  return `window.__MAAB_QPC_STATE__.phase='ORIGINAL_LAYOUT_READY';
const blockNodes=[...root.querySelectorAll(':scope > .line')];
if(blockNodes.length===0)throw new Error('phone-native visual blocks are missing');
const transformedBlocks=blockNodes.map((node)=>{const value=node.getBoundingClientRect();return{line:Number(node.dataset.line),type:node.dataset.type||'ayah',source_x:roundNumber(value.left),source_y:roundNumber(value.top),source_width:roundNumber(value.width),source_height:roundNumber(value.height),translation_y:0,x:roundNumber(value.left),y:roundNumber(value.top),width:roundNumber(value.width),height:roundNumber(value.height)}}).sort((left,right)=>left.line-right.line);
if(new Set(transformedBlocks.map((block)=>block.line)).size!==transformedBlocks.length)throw new Error('phone-native visual block line identities are not unique');
for(let index=1;index<transformedBlocks.length;index+=1){const previous=transformedBlocks[index-1],block=transformedBlocks[index];if(block.y<previous.y+previous.height-.02)throw new Error('phone-native visual blocks overlap at lines '+previous.line+' and '+block.line);${gapValidation}}
const finalTop=Math.min(...transformedBlocks.map((block)=>block.y));const finalBottom=Math.max(...transformedBlocks.map((block)=>block.y+block.height));
${distributionValidation}
window.__MAAB_QPC_VISUAL_BLOCKS__=transformedBlocks;`;
}

function renderHtml(page, lines, validAyahs) {
  const pageFont = pathToFileURL(sourcePath(`fonts/qpcv4/p${page}.woff2`)).href;
  const hasHeading = lines.some((line) => line.type === 'surah_name');
  const hasBasmallah = lines.some((line) => line.type === 'basmallah');
  const generatedSpecials = Boolean(activeLayout);
  const openingPageLayout = usesPhoneNativeOpeningPageLayout(page);
  const ayahCounts = new Map();
  for (const key of validAyahs) {
    const [surah, ayah] = key.split(':').map(Number);
    ayahCounts.set(surah, Math.max(ayahCounts.get(surah) ?? 0, ayah));
  }
  const headingCrop = { top: .265, bottom: .690 };
  const headingSource = generatedSpecials ? pngDimensions(surahHeaderLightAsset) : null;
  const contentWidth = generatedSpecials ? WIDTH - activeLayout.horizontalPadding * 2 : 0;
  const headingReferenceWidth = generatedSpecials ? round2(contentWidth * .95) : 0;
  const headingWidth = generatedSpecials ? round2(contentWidth) : 0;
  const headingFullHeight = headingSource ? round2(headingWidth * headingSource.height / headingSource.width) : 0;
  const headingHeight = headingSource ? round2(headingFullHeight * (headingCrop.bottom - headingCrop.top)) : 0;
  const headingReferenceFullHeight = headingSource ? round2(headingReferenceWidth * headingSource.height / headingSource.width) : 0;
  const headingReferenceHeight = headingSource ? round2(headingReferenceFullHeight * (headingCrop.bottom - headingCrop.top)) : 0;
  const headingLayoutCompensation = headingSource ? round2(headingHeight - headingReferenceHeight) : 0;
  const headingTitleSize = headingSource ? round2(headingReferenceHeight * .57) : 42;
  const headingMetadataLabelSize = headingSource ? round2(headingReferenceHeight * .20) : 0;
  const headingMetadataValueSize = headingSource ? round2(headingReferenceHeight * .20) : 0;
  const basmalaWidth = generatedSpecials ? round2((WIDTH - activeLayout.horizontalPadding * 2) * .46) : 0;
  const basmalaHeight = generatedSpecials ? round2(headingReferenceHeight * .94) : 84;
  const headingAssetUrl = headingSource ? pathToFileURL(surahHeaderLightAsset).href : '';
  const faces = [`@font-face{font-family:"QPCPage${page}";src:url("${pageFont}") format("woff2");font-display:block}`];
  if (hasHeading) faces.push(`@font-face{font-family:"SurahNameV4";src:url("${pathToFileURL(sourcePath('fonts/surah-name-v4.woff2')).href}") format("woff2");font-display:block}`);
  if (generatedSpecials && hasHeading) {
    requireInvariant(nonEmptyFile(medallionMetadataFontAsset), `required medallion metadata font is missing or empty: ${medallionMetadataFontAsset}`);
    faces.push(`@font-face{font-family:"MushafMedallionMetadata";src:url("${pathToFileURL(medallionMetadataFontAsset).href}") format("truetype");font-weight:700;font-display:block}`);
  }
  if (hasBasmallah) faces.push(`@font-face{font-family:"QCF4Hafs01";src:url("${pathToFileURL(sourcePath('fonts/QCF4_Hafs_01_W.woff2')).href}") format("woff2");font-display:block}`);
  const content = lines.map((line) => {
    if (line.type === 'surah_name') {
      if (!generatedSpecials) return `<div class="line special heading" data-line="${line.line}" data-type="surah_heading" data-surah="${line.surah}"><span>&#57344;&#${57344 + line.surah};</span></div>`;
      const ayahCount = ayahCounts.get(line.surah);
      requireInvariant(Number.isInteger(ayahCount) && ayahCount > 0, `missing Ayah count for Surah ${line.surah}`);
      return `<div class="line special heading" data-line="${line.line}" data-type="surah_heading" data-surah="${line.surah}"><div class="special-visual heading-visual" data-line="${line.line}" data-type="surah_heading" data-surah="${line.surah}"><img class="heading-frame" src="${headingAssetUrl}" alt=""><span class="heading-medallion heading-ayah-count"><span class="heading-medallion-copy"><span class="heading-medallion-label">آياتها</span><span class="heading-medallion-value">${arabicNumber(ayahCount)}</span></span></span><span class="heading-title"><span class="heading-prefix">&#57344;</span><span class="heading-name">&#${57344 + line.surah};</span></span><span class="heading-medallion heading-surah-order"><span class="heading-medallion-copy"><span class="heading-medallion-label">ترتيبها</span><span class="heading-medallion-value">${arabicNumber(line.surah)}</span></span></span></div></div>`;
    }
    if (line.type === 'basmallah') {
      if (!generatedSpecials) return `<div class="line special basmala" data-line="${line.line}" data-type="basmala"><span>&#63709;</span></div>`;
      return `<div class="line special basmala" data-line="${line.line}" data-type="basmala"><span class="special-visual basmala-visual" data-line="${line.line}" data-type="basmala">&#63709;</span></div>`;
    }
    const items = line.items.map((item) => `<span class="item" data-id="${item.id}" data-location="${html(item.location)}" data-surah="${item.surah}" data-ayah="${item.ayah}" data-position="${item.position}" data-line="${line.line}" data-kind="${item.classification}" data-key="${item.wordKey ?? ''}">${html(item.glyph)}</span>`).join('');
    return `<div class="line ayah${line.centered ? ' centered' : ''}" data-line="${line.line}">${items}</div>`;
  }).join('\n');
  const fonts = [`${FONT_SIZE}px QPCPage${page}`];
  if (hasHeading) fonts.push(`${headingTitleSize}px SurahNameV4`);
  if (generatedSpecials && hasHeading) fonts.push(`${headingMetadataLabelSize}px MushafMedallionMetadata`);
  if (hasBasmallah) fonts.push('44px QCF4Hafs01');

  const sheetWidth = activeLayout ? WIDTH : 1110;
  const sheetHeight = activeLayout ? HEIGHT : 1740;
  const sheetMargin = activeLayout ? '0' : '30px auto';
  const sheetPadding = activeLayout
    ? `${activeLayout.targetContentTop}px ${activeLayout.horizontalPadding}px ${HEIGHT - activeLayout.targetContentBottom}px`
    : '68px 76px 72px';
  const linesHeight = activeLayout
    ? activeLayout.targetContentBottom - activeLayout.targetContentTop
    : 1530;
  const linesDistributionCss = openingPageLayout
    ? `justify-content:center;gap:${PHONE_NATIVE_OPENING_PAGE_LAYOUT.lineGap}px`
    : 'justify-content:space-between';
  const sheetBorder = activeLayout ? '0' : '1px solid transparent';
  const folioCss = generatedSpecials
    ? ''
    : '.folio{position:absolute;bottom:30px;left:0;right:0;text-align:center;font:24px Georgia;color:#554a36}';
  const folioMarkup = generatedSpecials
    ? ''
    : `<div class="folio">${arabicNumber(page)}</div>`;
  const specialCss = generatedSpecials
    ? `.heading{height:${headingHeight}px;min-height:${headingHeight}px;margin-bottom:-${headingLayoutCompensation}px}.heading:last-child{margin-top:-${headingLayoutCompensation}px;margin-bottom:0}.heading-visual{position:relative;width:${headingWidth}px;height:${headingHeight}px;overflow:hidden;display:flex;align-items:center;justify-content:center}.heading-frame{position:absolute;z-index:0;left:0;top:${round2(-headingCrop.top * headingFullHeight)}px;width:${headingWidth}px;height:${headingFullHeight}px;max-width:none}.heading-title{position:relative;z-index:1;display:flex;direction:rtl;flex-direction:row;align-items:center;justify-content:center;max-width:44%;font-family:"SurahNameV4";font-size:${headingTitleSize}px;line-height:1}.heading-prefix,.heading-name{display:inline-block;unicode-bidi:isolate}.heading-medallion{position:absolute;z-index:1;top:0;width:14%;height:100%;display:flex;align-items:center;justify-content:center;direction:rtl;transform:translateY(-6px)}.heading-medallion-copy{position:relative;z-index:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:5px;color:#26372f;font-family:"MushafMedallionMetadata";font-weight:700;text-align:center}.heading-medallion-label{display:block;font-size:${headingMetadataLabelSize}px;line-height:.86;white-space:nowrap}.heading-medallion-value{display:block;direction:ltr;font-size:${headingMetadataValueSize}px;line-height:.86;white-space:nowrap}.heading-ayah-count{left:12%}.heading-ayah-count .heading-medallion-copy{transform:translate(4px,5px)}.heading-surah-order{right:12%}.heading-surah-order .heading-medallion-copy{transform:translate(-4px,5px)}.basmala{height:${basmalaHeight}px;min-height:${basmalaHeight}px}.basmala-visual{display:inline-block;transform:translateY(-6px);font-family:"QCF4Hafs01";font-size:44px;line-height:1}`
    : '.heading{height:84px}.heading span{font-family:"SurahNameV4";font-size:42px}.basmala{height:84px}.basmala span{font-family:"QCF4Hafs01";font-size:44px}';
  const visualRegionSelector = generatedSpecials ? '.special-visual' : '.special';
  const clippedContentSelector = generatedSpecials ? '.item,.special-visual' : '.item,.special';
  const finalizeSpecialsScript = generatedSpecials
    ? `for(const node of document.querySelectorAll('.basmala-visual')){const natural=node.getBoundingClientRect().width;if(!(natural>0))throw new Error('QPC basmala glyph is not measurable');const current=parseFloat(getComputedStyle(node).fontSize);node.style.fontSize=(Math.round(current*${basmalaWidth}/natural*100)/100)+'px'}`
    : '';
  return `<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><style>
${faces.join('\n')}*{box-sizing:border-box}html,body{width:${WIDTH}px;height:${HEIGHT}px;margin:0;overflow:hidden;text-size-adjust:none;-webkit-text-size-adjust:none;background:transparent}body{color:#17130e}.sheet{position:relative;width:${sheetWidth}px;height:${sheetHeight}px;margin:${sheetMargin};padding:${sheetPadding};overflow:hidden;background:transparent;border:${sheetBorder};box-shadow:none;visibility:hidden}body.ready .sheet{visibility:visible}.rules{position:absolute;inset:25px;border:1px solid transparent}.lines{height:${linesHeight}px;display:flex;flex-direction:column;${linesDistributionCss}}.line{width:100%;min-height:84px;display:flex;direction:rtl;align-items:center;justify-content:space-between;white-space:nowrap;font-family:"QPCPage${page}";font-size:${FONT_SIZE}px;line-height:1;font-variant-ligatures:none}.centered,.special{justify-content:center}.item{display:inline-block;flex:0 0 auto}${specialCss}${folioCss}#result{display:none}</style></head><body>
<main class="sheet" id="sheet"><div class="rules"></div><div class="lines" id="lines">${content}</div>${folioMarkup}</main><script id="result" type="application/json"></script><script>
window.__MAAB_QPC_STATE__={phase:'DOCUMENT_READY',ready:false,error:null};window.__MAAB_QPC_RESULT__=null;
  (async()=>{try{window.__MAAB_QPC_STATE__.phase='FONT_READY';const required=${JSON.stringify(fonts)};await Promise.all(required.map((font)=>document.fonts.load(font)));await document.fonts.ready;const font_status=required.map((font)=>({font,loaded:document.fonts.check(font)}));if(font_status.some((entry)=>!entry.loaded))throw new Error('required font failed readiness check');const images=[...document.images];await Promise.all(images.map((image)=>image.decode()));if(images.some((image)=>!image.complete||image.naturalWidth<=0))throw new Error('required image failed readiness check');window.__MAAB_QPC_STATE__.phase='DOM_READY';const root=document.getElementById('lines'),available=root.clientWidth;for(const line of document.querySelectorAll('.ayah')){const items=[...line.querySelectorAll('.item')],natural=items.reduce((sum,node)=>sum+node.getBoundingClientRect().width,0);if(natural>available&&natural>0){const current=parseFloat(getComputedStyle(line).fontSize);line.style.fontSize=Math.max(38,current*available/natural*.992)+'px'}}${finalizeSpecialsScript}await new Promise((resolve)=>requestAnimationFrame(()=>requestAnimationFrame(resolve)));const roundNumber=(value)=>Math.round(value*100)/100;${phoneNativeTransformScript(page, headingLayoutCompensation)}const round=roundNumber;const rect=(node)=>{const r=node.getBoundingClientRect();return{x:round(r.left),y:round(r.top),width:round(r.width),height:round(r.height)}};const items=[...document.querySelectorAll('.item')].map((node)=>({source_id:Number(node.dataset.id),source_location:node.dataset.location,surah:Number(node.dataset.surah),ayah:Number(node.dataset.ayah),position:Number(node.dataset.position),line:Number(node.dataset.line),classification:node.dataset.kind,word_key:node.dataset.key||null,...rect(node)}));if(items.length===0)throw new Error('expected Quran word elements are missing');if(items.some((item)=>!(item.width>0&&item.height>0)))throw new Error('one or more Quran word elements are not measurable');const visual_only=[...document.querySelectorAll(${JSON.stringify(visualRegionSelector)})].map((node)=>({type:node.dataset.type,page:${page},line:Number(node.dataset.line),surah:node.dataset.surah?Number(node.dataset.surah):null,...rect(node)}));const sheet=document.getElementById('sheet').getBoundingClientRect(),area=${activeLayout ? 'sheet' : 'root.getBoundingClientRect()'};const outside=(r,b)=>r.left<b.left-.5||r.right>b.right+.5||r.top<b.top-.5||r.bottom>b.bottom+.5;const clipped=[...document.querySelectorAll('.line')].some((node)=>outside(node.getBoundingClientRect(),sheet))||[...document.querySelectorAll(${JSON.stringify(clippedContentSelector)})].some((node)=>outside(node.getBoundingClientRect(),area));window.__MAAB_QPC_STATE__.phase='GEOMETRY_READY';const result={ready:true,font_status,clipped,item_regions:items,visual_only_regions:visual_only,visual_blocks:window.__MAAB_QPC_VISUAL_BLOCKS__||null};window.__MAAB_QPC_RESULT__=result;document.getElementById('result').textContent=JSON.stringify(result);document.body.classList.add('ready');window.__MAAB_QPC_STATE__={phase:'READY',ready:true,error:null};window.dispatchEvent(new Event('maab-qpc-ready'))}catch(error){const message=String(error&&error.message||error),failure_phase=window.__MAAB_QPC_STATE__.phase;document.getElementById('result').textContent=JSON.stringify({ready:false,error:message});window.__MAAB_QPC_STATE__={phase:'ERROR',failure_phase,ready:false,error:message};window.dispatchEvent(new Event('maab-qpc-ready'))}})();
</script></body></html>`;
}

async function boundedBrowserOperation(operation, page, phase, timeoutMs = BROWSER_TIMEOUT_MS) {
  return new Promise((resolve, reject) => {
    const scope = page > 0 ? `page ${page}: ` : '';
    const timer = setTimeout(() => reject(new BrowserProcessError(`${scope}timed out during ${phase} after ${timeoutMs}ms`)), timeoutMs);
    operation.then(
      (value) => { clearTimeout(timer); resolve(value); },
      (error) => { clearTimeout(timer); reject(error); },
    );
  });
}

class CdpConnection {
  constructor(socket) {
    this.socket = socket;
    this.nextId = 1;
    this.pending = new Map();
    this.listeners = new Set();
    socket.addEventListener('message', (event) => this.handleMessage(event.data));
    socket.addEventListener('close', () => this.failPending(new BrowserProcessError('browser CDP connection closed unexpectedly')));
    socket.addEventListener('error', () => this.failPending(new BrowserProcessError('browser CDP connection failed')));
  }

  static async open(url) {
    const socket = new WebSocket(url);
    await new Promise((resolve, reject) => {
      socket.addEventListener('open', resolve, { once: true });
      socket.addEventListener('error', () => reject(new BrowserProcessError('browser CDP WebSocket failed to open')), { once: true });
    });
    return new CdpConnection(socket);
  }

  handleMessage(data) {
    const text = typeof data === 'string' ? data : Buffer.from(data).toString('utf8');
    let message;
    try { message = JSON.parse(text); } catch (_) { return; }
    if (message.id) {
      const pending = this.pending.get(message.id);
      if (!pending) return;
      this.pending.delete(message.id);
      if (message.error) pending.reject(new Error(`${pending.method}: ${message.error.message}`));
      else pending.resolve(message.result ?? {});
      return;
    }
    for (const listener of [...this.listeners]) {
      if (listener.method === message.method && (!listener.sessionId || listener.sessionId === message.sessionId)) {
        this.listeners.delete(listener);
        listener.resolve(message.params ?? {});
      }
    }
  }

  failPending(error) {
    for (const pending of this.pending.values()) pending.reject(error);
    this.pending.clear();
    for (const listener of this.listeners) listener.reject(error);
    this.listeners.clear();
  }

  send(method, params = {}, sessionId = undefined) {
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { method, resolve, reject });
      this.socket.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
    });
  }

  waitForEvent(method, sessionId) {
    return new Promise((resolve, reject) => this.listeners.add({ method, sessionId, resolve, reject }));
  }

  closeSocket() {
    try { this.socket.close(); } catch (_) { /* browser shutdown may already have closed it */ }
  }
}

async function launchCdpBrowser(executable) {
  const profile = path.join(workRoot, `cdp-profile-${process.pid}`);
  fs.rmSync(profile, { recursive: true, force: true });
  ensureDirectory(profile);
  const browserProcess = childProcess.spawn(executable, [
    '--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files',
    '--disable-background-networking', '--no-first-run', '--no-default-browser-check',
    '--remote-debugging-port=0', `--user-data-dir=${profile}`,
    `--force-device-scale-factor=${SCALE}`, `--window-size=${WIDTH},${HEIGHT}`, 'about:blank',
  ], { stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true });

  const endpoint = new Promise((resolve, reject) => {
    let diagnostic = '';
    const inspect = (chunk) => {
      diagnostic += chunk.toString('utf8');
      const match = diagnostic.match(/DevTools listening on (ws:\/\/[^\s]+)/);
      if (match) resolve(match[1]);
      if (diagnostic.length > 16384) diagnostic = diagnostic.slice(-16384);
    };
    browserProcess.stdout.on('data', inspect);
    browserProcess.stderr.on('data', inspect);
    browserProcess.once('error', (error) => reject(new BrowserProcessError(`browser launch failed: ${error.message}`)));
    browserProcess.once('exit', (code) => reject(new BrowserProcessError(`browser exited during launch (exit ${code})`)));
  });

  let webSocketUrl;
  try {
    webSocketUrl = await boundedBrowserOperation(endpoint, 0, 'BROWSER_LAUNCH');
  } catch (error) {
    browserProcess.kill('SIGKILL');
    throw error;
  }
  const connection = await boundedBrowserOperation(CdpConnection.open(webSocketUrl), 0, 'BROWSER_LAUNCH');
  return { process: browserProcess, connection, profile };
}

async function closeCdpBrowser(browser) {
  try { await boundedBrowserOperation(browser.connection.send('Browser.close'), 0, 'BROWSER_CLOSE'); } catch (_) { browser.process.kill('SIGKILL'); }
  browser.connection.closeSocket();
  try { fs.rmSync(browser.profile, { recursive: true, force: true }); } catch (_) { /* transient profile is isolated */ }
}

function validateRect(rectangle, page, label, viewport = { width: WIDTH, height: HEIGHT }) {
  for (const key of ['x', 'y', 'width', 'height']) {
    requireInvariant(finite(rectangle[key]), `page ${page}: ${label} has non-finite ${key}`);
    requireInvariant(rectangle[key] >= 0, `page ${page}: ${label} has negative ${key}`);
  }
  requireInvariant(rectangle.width > 0 && rectangle.height > 0, `page ${page}: ${label} is empty`);
  requireInvariant(rectangle.x + rectangle.width <= viewport.width + .5 && rectangle.y + rectangle.height <= viewport.height + .5, `page ${page}: ${label} is outside viewport`);
}

function validatePhoneNativeGeometry(page, geometry, lines) {
  requireInvariant(geometry.layout === PHONE_NATIVE_LAYOUT.name, `page ${page}: phone-native layout identity is missing`);
  requireInvariant(Array.isArray(geometry.visual_blocks) && geometry.visual_blocks.length === lines.length,
    `page ${page}: phone-native visual block coverage is incomplete`);
  const openingPageLayout = usesPhoneNativeOpeningPageLayout(page);
  const byLine = new Map();
  const nearlyEqual = (left, right) => Math.abs(left - right) <= .02;
  for (let index = 0; index < geometry.visual_blocks.length; index += 1) {
    const block = geometry.visual_blocks[index];
    validateRect(block, page, `visual block line ${block.line}`, geometry.viewport);
    requireInvariant(Number.isInteger(block.line) && !byLine.has(block.line), `page ${page}: duplicate/invalid visual block line ${block.line}`);
    requireInvariant(['ayah', 'surah_heading', 'basmala'].includes(block.type), `page ${page}: invalid visual block type ${block.type}`);
    for (const key of ['source_x', 'source_y', 'source_width', 'source_height', 'translation_y']) {
      requireInvariant(finite(block[key]), `page ${page}: visual block line ${block.line} has invalid ${key}`);
    }
    requireInvariant(
      nearlyEqual(block.x, block.source_x) &&
      nearlyEqual(block.width, block.source_width) &&
      nearlyEqual(block.height, block.source_height) &&
      nearlyEqual(block.y, round2(block.source_y + block.translation_y)),
      `page ${page}: visual block line ${block.line} changed size/X or has an invalid Y translation`,
    );
    if (index > 0) {
      const previous = geometry.visual_blocks[index - 1];
      requireInvariant(block.y >= previous.y + previous.height - .02,
        `page ${page}: visual blocks ${previous.line} and ${block.line} overlap`);
      if (openingPageLayout && previous.type !== 'surah_heading') {
        requireInvariant(
          Math.abs(block.y - (previous.y + previous.height) - PHONE_NATIVE_OPENING_PAGE_LAYOUT.lineGap) <= .05,
          `page ${page}: opening-page line gap mismatch between lines ${previous.line} and ${block.line}`,
        );
      }
    }
    byLine.set(block.line, block);
  }
  const top = Math.min(...geometry.visual_blocks.map((block) => block.y));
  const bottom = Math.max(...geometry.visual_blocks.map((block) => block.y + block.height));
  const absoluteTop = geometry.source_content_bounds?.top ?? top;
  const absoluteBottom = geometry.source_content_bounds?.bottom ?? bottom;
  if (openingPageLayout) {
    const targetCenter = (PHONE_NATIVE_LAYOUT.targetContentTop + PHONE_NATIVE_LAYOUT.targetContentBottom) / 2;
    requireInvariant(
      absoluteTop >= PHONE_NATIVE_LAYOUT.targetContentTop - PHONE_NATIVE_LAYOUT.distributionTolerance &&
      absoluteBottom <= PHONE_NATIVE_LAYOUT.targetContentBottom + PHONE_NATIVE_LAYOUT.distributionTolerance &&
      Math.abs((absoluteTop + absoluteBottom) / 2 - targetCenter) <= PHONE_NATIVE_LAYOUT.distributionTolerance,
      `page ${page}: phone-native opening-page content is not centered in the target area`,
    );
  } else {
    requireInvariant(
      Math.abs(absoluteTop - PHONE_NATIVE_LAYOUT.targetContentTop) <= PHONE_NATIVE_LAYOUT.distributionTolerance &&
      Math.abs(absoluteBottom - PHONE_NATIVE_LAYOUT.targetContentBottom) <= PHONE_NATIVE_LAYOUT.distributionTolerance,
      `page ${page}: phone-native content does not span the target distribution area`,
    );
  }
  const belongsToBlock = (region) => {
    const block = byLine.get(region.line);
    return block &&
      region.x >= block.x - .5 && region.x + region.width <= block.x + block.width + .5 &&
      region.y >= block.y - .5 && region.y + region.height <= block.y + block.height + .5;
  };
  for (const region of [...geometry.word_regions, ...geometry.non_word_regions, ...geometry.visual_only_regions]) {
    requireInvariant(belongsToBlock(region), `page ${page}: region on line ${region.line} escaped its owning visual block`);
  }
}

function geometryFor(page, lines, result, validAyahs) {
  const validLines = new Set(lines.map((line) => line.line));
  const words = [], nonWords = [], pageKeys = new Set();
  for (const item of result.item_regions) {
    validateRect(item, page, `item ${item.source_id}`);
    requireInvariant(validLines.has(item.line), `page ${page}: item ${item.source_id} uses invalid line`);
    requireInvariant(Number.isInteger(item.surah) && item.surah >= 1 && item.surah <= 114, `page ${page}: invalid Surah on item ${item.source_id}`);
    requireInvariant(Number.isInteger(item.ayah) && item.ayah >= 1 && validAyahs.has(`${item.surah}:${item.ayah}`), `page ${page}: invalid Ayah on item ${item.source_id}`);
    const region = { page, line: item.line, surah: item.surah, ayah: item.ayah, position: item.position, x: item.x, y: item.y, width: item.width, height: item.height };
    if (item.classification === 'quran_word') {
      const key = `${item.surah}:${item.ayah}:${item.position}`;
      requireInvariant(item.word_key === key && !pageKeys.has(key), `page ${page}: invalid/duplicate WordKey ${key}`);
      pageKeys.add(key); words.push({ word_key: key, ...region });
    } else {
      requireInvariant(item.classification === 'ayah_marker' && item.word_key === null, `page ${page}: invalid non-word classification/key`);
      nonWords.push({ type: 'ayah_marker', source_id: item.source_id, ayah_key: `${item.surah}:${item.ayah}`, ...region });
    }
  }
  requireInvariant(words.length > 0, `page ${page}: no Quran word rectangles`);
  const grouped = new Map();
  for (const word of words) {
    const key = `${word.surah}:${word.ayah}`;
    if (!grouped.has(key)) grouped.set(key, new Map());
    if (!grouped.get(key).has(word.line)) grouped.get(key).set(word.line, []);
    grouped.get(key).get(word.line).push(word);
  }
  const ayahs = [...grouped.entries()].map(([key, byLine]) => {
    const [surah, ayah] = key.split(':').map(Number);
    const line_regions = [...byLine.entries()].sort((a, b) => a[0] - b[0]).map(([line, lineWords]) => {
      requireInvariant(lineWords.length > 0, `page ${page}: Ayah ${key}, line ${line} has no Quran words`);
      const left = Math.min(...lineWords.map((word) => word.x)), top = Math.min(...lineWords.map((word) => word.y));
      const right = Math.max(...lineWords.map((word) => word.x + word.width)), bottom = Math.max(...lineWords.map((word) => word.y + word.height));
      const region = { line, x: round2(left), y: round2(top), width: round2(right - left), height: round2(bottom - top), word_count: lineWords.length };
      validateRect(region, page, `Ayah ${key}, line ${line}`); return region;
    });
    requireInvariant(line_regions.length > 0, `page ${page}: Ayah ${key} has no regions`);
    return { ayah_key: key, page, surah, ayah, line_regions };
  });
  for (const item of result.visual_only_regions) {
    validateRect(item, page, `${item.type}, line ${item.line}`);
    requireInvariant(validLines.has(item.line) && ['surah_heading', 'basmala'].includes(item.type), `page ${page}: invalid visual-only item`);
    if (item.type === 'surah_heading') requireInvariant(Number.isInteger(item.surah) && item.surah >= 1 && item.surah <= 114, `page ${page}: invalid heading Surah`);
  }
  const geometry = { schema_version: SCHEMA, render_fingerprint: RENDER_FINGERPRINT, page, viewport: { width: WIDTH, height: HEIGHT, units: 'pixels', origin: 'top-left', device_scale_factor: SCALE }, word_regions: words, non_word_regions: nonWords, ayah_regions: ayahs, visual_only_regions: result.visual_only_regions };
  if (activeLayout) {
    geometry.layout = activeLayout.name;
    if (usesPhoneNativeOpeningPageLayout(page)) geometry.opening_page_layout = PHONE_NATIVE_OPENING_PAGE_LAYOUT.version;
    if (hasTerminalSurahHeading(lines)) geometry.terminal_heading_layout = PHONE_NATIVE_TERMINAL_HEADING_LAYOUT;
    geometry.visual_blocks = result.visual_blocks;
    validatePhoneNativeGeometry(page, geometry, lines);
  }
  return geometry;
}

function cropPhoneNativeGeometry(geometry, crop) {
  requireInvariant(activeLayout, 'geometry cropping requires phone-native layout');
  const translateRect = (rectangle) => {
    const left = Math.max(rectangle.x, crop.x);
    const top = Math.max(rectangle.y, crop.y);
    const right = Math.min(rectangle.x + rectangle.width, crop.x + crop.width);
    const bottom = Math.min(rectangle.y + rectangle.height, crop.y + crop.height);
    requireInvariant(right > left && bottom > top, `cropped geometry region does not intersect visible page bounds`);
    return {
      ...rectangle,
      x: round2(left - crop.x),
      y: round2(top - crop.y),
      width: round2(right - left),
      height: round2(bottom - top),
    };
  };
  const cropped = {
    ...geometry,
    source_canvas: { width: WIDTH, height: HEIGHT },
    crop_origin: { x: crop.x, y: crop.y },
    source_content_bounds: {
      top: Math.min(...geometry.visual_blocks.map((block) => block.y)),
      bottom: Math.max(...geometry.visual_blocks.map((block) => block.y + block.height)),
    },
    viewport: {
      ...geometry.viewport,
      width: crop.width,
      height: crop.height,
    },
    word_regions: geometry.word_regions.map(translateRect),
    non_word_regions: geometry.non_word_regions.map(translateRect),
    ayah_regions: geometry.ayah_regions.map((ayah) => ({
      ...ayah,
      line_regions: ayah.line_regions.map(translateRect),
    })),
    visual_only_regions: geometry.visual_only_regions.map(translateRect),
    visual_blocks: geometry.visual_blocks.map((block) => {
      const translated = translateRect(block);
      return {
        ...translated,
        source_x: translated.x,
        source_y: translated.y,
        source_width: translated.width,
        source_height: translated.height,
        translation_y: 0,
      };
    }),
  };
  return cropped;
}

function validateGeometryDocument(page, geometry, lines, validAyahs) {
  requireInvariant(geometry && geometry.schema_version === SCHEMA && geometry.render_fingerprint === RENDER_FINGERPRINT && geometry.page === page, `page ${page}: geometry schema/fingerprint/page mismatch`);
  if (usesPhoneNativeOpeningPageLayout(page)) {
    requireInvariant(
      geometry.opening_page_layout === PHONE_NATIVE_OPENING_PAGE_LAYOUT.version,
      `page ${page}: opening-page layout revision mismatch`,
    );
  }
  if (activeLayout && hasTerminalSurahHeading(lines)) {
    requireInvariant(
      geometry.terminal_heading_layout === PHONE_NATIVE_TERMINAL_HEADING_LAYOUT,
      `page ${page}: terminal-heading layout revision mismatch`,
    );
  }
  const viewport = geometry.viewport;
  const validViewport = activeLayout
    ? Number.isInteger(viewport?.width) && viewport.width > 0 && viewport.width <= WIDTH &&
      Number.isInteger(viewport?.height) && viewport.height > 0 && viewport.height <= HEIGHT &&
      geometry.source_canvas?.width === WIDTH && geometry.source_canvas?.height === HEIGHT &&
      Number.isInteger(geometry.crop_origin?.x) && Number.isInteger(geometry.crop_origin?.y)
    : viewport?.width === WIDTH && viewport?.height === HEIGHT;
  requireInvariant(validViewport && viewport?.units === 'pixels' && viewport?.origin === 'top-left' && viewport?.device_scale_factor === SCALE,
    `page ${page}: geometry viewport mismatch`);
  for (const key of ['word_regions', 'non_word_regions', 'ayah_regions', 'visual_only_regions']) {
    requireInvariant(Array.isArray(geometry[key]), `page ${page}: geometry lacks ${key}`);
  }
  if (activeLayout) validatePhoneNativeGeometry(page, geometry, lines);
  const validLines = new Set(lines.map((line) => line.line));
  const expectedWords = new Set(lines.flatMap((line) => line.items ?? []).filter((item) => item.classification === 'quran_word').map((item) => item.wordKey));
  const expectedMarkers = new Set(lines.flatMap((line) => line.items ?? []).filter((item) => item.classification === 'ayah_marker').map((item) => item.id));
  const expectedVisual = new Set(lines.filter((line) => line.type !== 'ayah').map((line) => `${line.type === 'surah_name' ? 'surah_heading' : 'basmala'}:${line.line}`));
  const actualWords = new Set();
  const grouped = new Map();

  for (const word of geometry.word_regions) {
    validateRect(word, page, `WordKey ${word.word_key}`, viewport);
    requireInvariant(word.page === page && validLines.has(word.line), `page ${page}: WordKey ${word.word_key} uses invalid page/line`);
    requireInvariant(Number.isInteger(word.surah) && word.surah >= 1 && word.surah <= 114 && Number.isInteger(word.ayah) && word.ayah >= 1 && validAyahs.has(`${word.surah}:${word.ayah}`),
      `page ${page}: WordKey ${word.word_key} has invalid Surah/Ayah`);
    requireInvariant(Number.isInteger(word.position) && word.position >= 1, `page ${page}: WordKey ${word.word_key} has invalid position`);
    const expectedKey = `${word.surah}:${word.ayah}:${word.position}`;
    requireInvariant(word.word_key === expectedKey && expectedWords.has(expectedKey) && !actualWords.has(expectedKey), `page ${page}: invalid, unexpected, or duplicate WordKey ${word.word_key}`);
    actualWords.add(expectedKey);
    const ayahKey = `${word.surah}:${word.ayah}`;
    if (!grouped.has(ayahKey)) grouped.set(ayahKey, new Map());
    if (!grouped.get(ayahKey).has(word.line)) grouped.get(ayahKey).set(word.line, []);
    grouped.get(ayahKey).get(word.line).push(word);
  }
  requireInvariant(actualWords.size === expectedWords.size && [...expectedWords].every((key) => actualWords.has(key)), `page ${page}: Quran WordKey coverage is incomplete`);

  const actualMarkers = new Set();
  for (const marker of geometry.non_word_regions) {
    validateRect(marker, page, `ayah marker ${marker.source_id}`, viewport);
    requireInvariant(marker.type === 'ayah_marker' && Number.isInteger(marker.source_id) && expectedMarkers.has(marker.source_id) && !actualMarkers.has(marker.source_id),
      `page ${page}: invalid, unexpected, or duplicate Ayah marker ${marker.source_id}`);
    requireInvariant(marker.page === page && validLines.has(marker.line) && marker.ayah_key === `${marker.surah}:${marker.ayah}` && validAyahs.has(marker.ayah_key), `page ${page}: invalid Ayah marker identity`);
    actualMarkers.add(marker.source_id);
  }
  requireInvariant(actualMarkers.size === expectedMarkers.size, `page ${page}: Ayah marker coverage is incomplete`);

  const actualVisual = new Set();
  for (const visual of geometry.visual_only_regions) {
    validateRect(visual, page, `${visual.type}, line ${visual.line}`, viewport);
    const key = `${visual.type}:${visual.line}`;
    requireInvariant(visual.page === page && validLines.has(visual.line) && expectedVisual.has(key) && !actualVisual.has(key), `page ${page}: invalid, unexpected, or duplicate visual-only region ${key}`);
    if (visual.type === 'surah_heading') requireInvariant(Number.isInteger(visual.surah) && visual.surah >= 1 && visual.surah <= 114, `page ${page}: invalid surah heading identity`);
    actualVisual.add(key);
  }
  requireInvariant(actualVisual.size === expectedVisual.size, `page ${page}: visual-only region coverage is incomplete`);

  const nearlyEqual = (left, right) => Math.abs(left - right) <= 0.02;
  const actualAyahs = new Set();
  for (const ayah of geometry.ayah_regions) {
    const key = `${ayah.surah}:${ayah.ayah}`;
    requireInvariant(ayah.page === page && ayah.ayah_key === key && grouped.has(key) && !actualAyahs.has(key) && Array.isArray(ayah.line_regions) && ayah.line_regions.length > 0,
      `page ${page}: invalid, unexpected, duplicate, or empty Ayah region ${ayah.ayah_key}`);
    actualAyahs.add(key);
    const expectedLines = grouped.get(key);
    requireInvariant(ayah.line_regions.length === expectedLines.size, `page ${page}: Ayah ${key} line-region coverage differs from its words`);
    const seenLines = new Set();
    for (const region of ayah.line_regions) {
      validateRect(region, page, `Ayah ${key}, line ${region.line}`, viewport);
      const words = expectedLines.get(region.line);
      requireInvariant(words?.length && !seenLines.has(region.line), `page ${page}: Ayah ${key} has invalid/duplicate line ${region.line}`);
      seenLines.add(region.line);
      const left = Math.min(...words.map((word) => word.x)), top = Math.min(...words.map((word) => word.y));
      const right = Math.max(...words.map((word) => word.x + word.width)), bottom = Math.max(...words.map((word) => word.y + word.height));
      requireInvariant(region.word_count === words.length && nearlyEqual(region.x, round2(left)) && nearlyEqual(region.y, round2(top)) && nearlyEqual(region.width, round2(right - left)) && nearlyEqual(region.height, round2(bottom - top)),
        `page ${page}: Ayah ${key}, line ${region.line} is not the word-rectangle union`);
    }
  }
  requireInvariant(actualAyahs.size === grouped.size && [...grouped.keys()].every((key) => actualAyahs.has(key)), `page ${page}: Ayah region coverage is incomplete`);
  return {
    words: geometry.word_regions.length,
    ayahLines: geometry.ayah_regions.reduce((sum, ayah) => sum + ayah.line_regions.length, 0),
  };
}

const PNG_SIGNATURE = Buffer.from([137,80,78,71,13,10,26,10]);
const PNG_PALETTE_SIZE = 256;
const PNG_SEMANTIC_COLORS_PER_GROUP = 8;

function colorKey(r, g, b, a) { return (((r * 256 + g) * 256 + b) * 256 + a); }

function pngCrc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data = Buffer.alloc(0)) {
  const typeBytes = Buffer.from(type, 'ascii');
  const chunk = Buffer.alloc(12 + data.length);
  chunk.writeUInt32BE(data.length, 0);
  typeBytes.copy(chunk, 4);
  data.copy(chunk, 8);
  chunk.writeUInt32BE(pngCrc32(Buffer.concat([typeBytes, data])), 8 + data.length);
  return chunk;
}

function unfilterPngRows(packed, width, height, bytesPerPixel, page) {
  const stride = width * bytesPerPixel;
  requireInvariant(packed.length === (stride + 1) * height, `page ${page}: unexpected decoded PNG size`);
  const pixels = Buffer.alloc(stride * height);
  const paeth = (left, up, upperLeft) => {
    const estimate = left + up - upperLeft;
    const leftDistance = Math.abs(estimate - left), upDistance = Math.abs(estimate - up), upperLeftDistance = Math.abs(estimate - upperLeft);
    return leftDistance <= upDistance && leftDistance <= upperLeftDistance ? left : upDistance <= upperLeftDistance ? up : upperLeft;
  };
  for (let y = 0; y < height; y += 1) {
    const sourceRow = y * (stride + 1), targetRow = y * stride, filter = packed[sourceRow];
    requireInvariant(filter >= 0 && filter <= 4, `page ${page}: unsupported PNG row filter ${filter}`);
    for (let x = 0; x < stride; x += 1) {
      const raw = packed[sourceRow + 1 + x];
      const left = x >= bytesPerPixel ? pixels[targetRow + x - bytesPerPixel] : 0;
      const up = y > 0 ? pixels[targetRow - stride + x] : 0;
      const upperLeft = y > 0 && x >= bytesPerPixel ? pixels[targetRow - stride + x - bytesPerPixel] : 0;
      const predictor = filter === 0 ? 0 : filter === 1 ? left : filter === 2 ? up : filter === 3 ? Math.floor((left + up) / 2) : paeth(left, up, upperLeft);
      pixels[targetRow + x] = (raw + predictor) & 255;
    }
  }
  return pixels;
}

function decodeTransparentPng(file, page, expectedWidth = WIDTH, expectedHeight = HEIGHT) {
  requireInvariant(nonEmptyFile(file), `page ${page}: image missing/empty`);
  const png = fs.readFileSync(file);
  requireInvariant(png.length >= 33 && png.subarray(0, 8).equals(PNG_SIGNATURE), `page ${page}: output is not a complete PNG`);
  const width = png.readUInt32BE(16), height = png.readUInt32BE(20);
  const bitDepth = png[24], colorType = png[25], compression = png[26], filterMethod = png[27], interlace = png[28];
  requireInvariant(width === expectedWidth && height === expectedHeight, `page ${page}: PNG dimensions differ from canonical viewport`);
  requireInvariant(bitDepth === 8 && (colorType === 3 || colorType === 6), `page ${page}: PNG must be 8-bit RGBA or indexed; found bit depth ${bitDepth}, color type ${colorType}`);
  requireInvariant(compression === 0 && filterMethod === 0 && interlace === 0, `page ${page}: unsupported PNG encoding`);
  const idat = [];
  let palette = null, transparency = null, cursor = 8;
  while (cursor + 12 <= png.length) {
    const length = png.readUInt32BE(cursor);
    const type = png.subarray(cursor + 4, cursor + 8).toString('ascii');
    requireInvariant(cursor + 12 + length <= png.length, `page ${page}: truncated PNG chunk ${type}`);
    const data = png.subarray(cursor + 8, cursor + 8 + length);
    if (type === 'PLTE') palette = data;
    if (type === 'tRNS') transparency = data;
    if (type === 'IDAT') idat.push(data);
    cursor += 12 + length;
    if (type === 'IEND') break;
  }
  requireInvariant(idat.length > 0, `page ${page}: PNG has no image data`);
  const packed = zlib.inflateSync(Buffer.concat(idat));
  const bytesPerPixel = colorType === 6 ? 4 : 1;
  const decoded = unfilterPngRows(packed, width, height, bytesPerPixel, page);
  if (colorType === 6) return { width, height, pixels: decoded, colorType, paletteEntries: 0 };
  requireInvariant(palette && palette.length > 0 && palette.length % 3 === 0 && palette.length <= PNG_PALETTE_SIZE * 3,
    `page ${page}: indexed PNG palette is missing or malformed`);
  const paletteEntries = palette.length / 3;
  requireInvariant(!transparency || transparency.length <= paletteEntries, `page ${page}: indexed PNG transparency table is malformed`);
  const pixels = Buffer.alloc(width * height * 4);
  for (let index = 0; index < decoded.length; index += 1) {
    const paletteIndex = decoded[index];
    requireInvariant(paletteIndex < paletteEntries, `page ${page}: indexed PNG references palette entry ${paletteIndex}`);
    pixels[index * 4] = palette[paletteIndex * 3];
    pixels[index * 4 + 1] = palette[paletteIndex * 3 + 1];
    pixels[index * 4 + 2] = palette[paletteIndex * 3 + 2];
    pixels[index * 4 + 3] = transparency && paletteIndex < transparency.length ? transparency[paletteIndex] : 255;
  }
  return { width, height, pixels, colorType, paletteEntries };
}

function semanticColorGroup(color) {
  if (color.a < 224) return null;
  const maximum = Math.max(color.r, color.g, color.b), minimum = Math.min(color.r, color.g, color.b);
  if (maximum < 96) return 'ink';
  if (maximum - minimum < 36) return null;
  if (color.r >= color.g + 24 && color.r >= color.b + 24) return 'red';
  if (color.g >= color.r + 18 && color.g >= color.b + 18) return 'green';
  if (color.b >= color.r + 18 && color.b >= color.g + 18) return 'blue';
  if (color.r >= color.b + 30 && color.g >= color.b + 15) return 'gold';
  return null;
}

function colorBox(colors) {
  const minimum = [255,255,255,255], maximum = [0,0,0,0];
  let weight = 0;
  for (const color of colors) {
    const values = [color.r, color.g, color.b, color.a];
    for (let channel = 0; channel < 4; channel += 1) {
      minimum[channel] = Math.min(minimum[channel], values[channel]);
      maximum[channel] = Math.max(maximum[channel], values[channel]);
    }
    weight += color.count;
  }
  const ranges = maximum.map((value, channel) => value - minimum[channel]);
  const channelWeights = [.30, .59, .11, .50];
  let channel = 0;
  for (let index = 1; index < 4; index += 1) {
    if (ranges[index] * channelWeights[index] > ranges[channel] * channelWeights[channel]) channel = index;
  }
  const score = ranges[channel] * Math.log2(weight + 1);
  return { colors, weight, channel, score };
}

function splitColorBox(box) {
  if (box.colors.length < 2) return null;
  const channels = ['r', 'g', 'b', 'a'], channel = channels[box.channel];
  const colors = [...box.colors].sort((left, right) => left[channel] - right[channel] || left.key - right.key);
  const midpoint = box.weight / 2;
  let cumulative = 0, split = 1;
  for (; split < colors.length; split += 1) {
    cumulative += colors[split - 1].count;
    if (cumulative >= midpoint) break;
  }
  split = Math.max(1, Math.min(colors.length - 1, split));
  return [colorBox(colors.slice(0, split)), colorBox(colors.slice(split))];
}

function representativeColor(box) {
  let r = 0, g = 0, b = 0, a = 0;
  for (const color of box.colors) {
    r += color.r * color.count;
    g += color.g * color.count;
    b += color.b * color.count;
    a += color.a * color.count;
  }
  return {
    r: Math.round(r / box.weight), g: Math.round(g / box.weight),
    b: Math.round(b / box.weight), a: Math.max(1, Math.round(a / box.weight)),
  };
}

function buildQuranPalette(pixels) {
  const histogram = new Map();
  for (let offset = 0; offset < pixels.length; offset += 4) {
    const r = pixels[offset], g = pixels[offset + 1], b = pixels[offset + 2], a = pixels[offset + 3];
    if (a === 0) continue;
    const key = colorKey(r, g, b, a), existing = histogram.get(key);
    if (existing) existing.count += 1;
    else histogram.set(key, { key, r, g, b, a, count: 1 });
  }
  requireInvariant(histogram.size > 0, 'indexed PNG palette cannot be built from an empty image');
  const colors = [...histogram.values()].sort((left, right) => right.count - left.count || left.key - right.key);
  const palette = [{ r: 0, g: 0, b: 0, a: 0 }], reserved = new Set();
  const reserve = (color) => {
    if (!color || reserved.has(color.key) || palette.length >= PNG_PALETTE_SIZE) return;
    reserved.add(color.key);
    palette.push({ r: color.r, g: color.g, b: color.b, a: color.a });
  };
  for (const color of colors) {
    if (color.a === 255 && palette.length <= 16) reserve(color);
  }
  for (const group of ['ink', 'red', 'green', 'blue', 'gold']) {
    let count = 0;
    for (const color of colors) {
      if (semanticColorGroup(color) !== group) continue;
      reserve(color);
      count += 1;
      if (count === PNG_SEMANTIC_COLORS_PER_GROUP) break;
    }
  }
  const remaining = colors.filter((color) => !reserved.has(color.key));
  if (remaining.length > 0 && palette.length < PNG_PALETTE_SIZE) {
    const boxes = [colorBox(remaining)];
    const target = PNG_PALETTE_SIZE - palette.length;
    while (boxes.length < target) {
      let selected = -1;
      for (let index = 0; index < boxes.length; index += 1) {
        if (boxes[index].colors.length < 2) continue;
        if (selected < 0 || boxes[index].score > boxes[selected].score) selected = index;
      }
      if (selected < 0) break;
      const split = splitColorBox(boxes[selected]);
      if (!split) break;
      boxes.splice(selected, 1, ...split);
    }
    for (const box of boxes) palette.push(representativeColor(box));
  }
  const paletteKeys = new Set(palette.map((color) => colorKey(color.r, color.g, color.b, color.a)));
  for (const color of colors) {
    if (palette.length >= PNG_PALETTE_SIZE) break;
    if (paletteKeys.has(color.key)) continue;
    palette.push({ r: color.r, g: color.g, b: color.b, a: color.a });
    paletteKeys.add(color.key);
  }
  return { palette, histogram };
}

function paletteDistance(color, candidate) {
  const alpha = color.a / 255, candidateAlpha = candidate.a / 255;
  const red = color.r * alpha - candidate.r * candidateAlpha;
  const green = color.g * alpha - candidate.g * candidateAlpha;
  const blue = color.b * alpha - candidate.b * candidateAlpha;
  const alphaDifference = color.a - candidate.a;
  return 3 * red * red + 4 * green * green + 2 * blue * blue + 6 * alphaDifference * alphaDifference;
}

function encodeIndexedPng(decoded, destination, page) {
  const built = buildQuranPalette(decoded.pixels), palette = built.palette;
  const exact = new Map();
  for (let index = 0; index < palette.length; index += 1) {
    const color = palette[index];
    exact.set(colorKey(color.r, color.g, color.b, color.a), index);
  }
  const colorIndexes = new Map([[colorKey(0, 0, 0, 0), 0]]);
  for (const color of built.histogram.values()) {
    let best = exact.get(color.key);
    if (best === undefined) {
      best = 1;
      let bestDistance = Number.POSITIVE_INFINITY;
      for (let index = 1; index < palette.length; index += 1) {
        const distance = paletteDistance(color, palette[index]);
        if (distance < bestDistance) { bestDistance = distance; best = index; }
      }
    }
    colorIndexes.set(color.key, best);
  }
  const scanlines = Buffer.alloc((decoded.width + 1) * decoded.height);
  for (let y = 0; y < decoded.height; y += 1) {
    const row = y * (decoded.width + 1);
    scanlines[row] = 0;
    for (let x = 0; x < decoded.width; x += 1) {
      const offset = (y * decoded.width + x) * 4;
      const alpha = decoded.pixels[offset + 3];
      const key = alpha === 0 ? colorKey(0, 0, 0, 0) : colorKey(decoded.pixels[offset], decoded.pixels[offset + 1], decoded.pixels[offset + 2], alpha);
      scanlines[row + 1 + x] = colorIndexes.get(key);
    }
  }
  while (palette.length < PNG_PALETTE_SIZE) palette.push({ ...palette[palette.length - 1] });
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(decoded.width, 0);
  ihdr.writeUInt32BE(decoded.height, 4);
  ihdr[8] = 8;
  ihdr[9] = 3;
  const plte = Buffer.alloc(PNG_PALETTE_SIZE * 3), trns = Buffer.alloc(PNG_PALETTE_SIZE);
  for (let index = 0; index < PNG_PALETTE_SIZE; index += 1) {
    const color = palette[index];
    plte[index * 3] = color.r;
    plte[index * 3 + 1] = color.g;
    plte[index * 3 + 2] = color.b;
    trns[index] = color.a;
  }
  const encoded = Buffer.concat([
    PNG_SIGNATURE,
    pngChunk('IHDR', ihdr),
    pngChunk('PLTE', plte),
    pngChunk('tRNS', trns),
    pngChunk('IDAT', zlib.deflateSync(scanlines, { level: 9 })),
    pngChunk('IEND'),
  ]);
  fs.writeFileSync(destination, encoded);
  const verified = decodeTransparentPng(destination, page, decoded.width, decoded.height);
  requireInvariant(verified.colorType === 3 && verified.paletteEntries === PNG_PALETTE_SIZE,
    `page ${page}: indexed PNG encoding verification failed`);
}

function visiblePixelBounds(decoded, page) {
  let left = decoded.width;
  let top = decoded.height;
  let right = -1;
  let bottom = -1;
  for (let y = 0; y < decoded.height; y += 1) {
    for (let x = 0; x < decoded.width; x += 1) {
      if (decoded.pixels[(y * decoded.width + x) * 4 + 3] === 0) continue;
      left = Math.min(left, x);
      top = Math.min(top, y);
      right = Math.max(right, x);
      bottom = Math.max(bottom, y);
    }
  }
  requireInvariant(right >= left && bottom >= top, `page ${page}: rendered page has no visible pixels`);
  return { x: left, y: top, width: right - left + 1, height: bottom - top + 1 };
}

function validatePng(file, page, geometry) {
  const decoded = decodeTransparentPng(
    file,
    page,
    geometry.viewport.width,
    geometry.viewport.height,
  );
  requireInvariant(
    decoded.colorType === 3 && decoded.paletteEntries === PNG_PALETTE_SIZE,
    `page ${page}: final PNG must use an 8-bit 256-entry indexed palette`,
  );
  let transparent = false, visible = false;
  for (let offset = 3; offset < decoded.pixels.length && !(transparent && visible); offset += 4) {
    const alpha = decoded.pixels[offset];
    if (alpha === 0) transparent = true;
    if (alpha > 0) visible = true;
  }
  requireInvariant(transparent, `page ${page}: PNG contains no transparent pixels`);
  requireInvariant(visible, `page ${page}: PNG contains no visible content pixels`);
  if (activeLayout) {
    const bounds = visiblePixelBounds(decoded, page);
    requireInvariant(
      bounds.x === 0 && bounds.y === 0 &&
      bounds.width === decoded.width && bounds.height === decoded.height,
      `page ${page}: cropped PNG retains a fully transparent outer margin`,
    );
  }
  for (const word of geometry.word_regions) {
    const left = Math.max(0, Math.floor(word.x)), top = Math.max(0, Math.floor(word.y));
    const right = Math.min(decoded.width, Math.ceil(word.x + word.width)), bottom = Math.min(decoded.height, Math.ceil(word.y + word.height));
    let hasGlyphPixel = false;
    for (let y = top; y < bottom && !hasGlyphPixel; y += 1) {
      for (let x = left; x < right; x += 1) {
        if (decoded.pixels[(y * decoded.width + x) * 4 + 3] > 0) { hasGlyphPixel = true; break; }
      }
    }
    requireInvariant(hasGlyphPixel, `page ${page}: WordKey ${word.word_key} has no visible PNG pixels in its geometry`);
  }
}

function initializeOutput() {
  [pagesRoot, geometryRoot, licensesRoot, workRoot].forEach(ensureDirectory);
  const finalManifest = path.join(packRoot, 'manifest.json');
  const previousManifest = path.join(
    workRoot,
    activeLayout ? 'manifest.phone-native.previous.json' : 'manifest.previous.json',
  );
  if (fs.existsSync(finalManifest)) {
    fs.rmSync(previousManifest, { force: true });
    fs.renameSync(finalManifest, previousManifest);
  }
  const pinnedNotice = fs.readFileSync(sourcePath('LICENSE-NOTICE.md'));
  const spikeNotice = path.join(spikeRoot, 'data', 'upstream-LICENSE-NOTICE.md');
  if (nonEmptyFile(spikeNotice)) requireInvariant(fs.readFileSync(spikeNotice).equals(pinnedNotice), 'spike notice differs from pinned notice');
  fs.writeFileSync(path.join(licensesRoot, 'upstream-LICENSE-NOTICE.md'), pinnedNotice);
  const readme = activeLayout
    ? `# QPC V4 Tajweed phone-native 604-page research pack\n\n**RESEARCH ONLY — NOT FOR RELEASE**\n\n604 tightly cropped transparent 8-bit indexed PNG rasters with deterministic 256-entry RGBA palettes and matching gzip-compressed geometry generated from pinned commit \`${COMMIT}\`. Pages are laid out on a ${WIDTH} × ${HEIGHT} source canvas, then cropped to their exact nonzero-alpha bounds; each geometry viewport records its page's final PNG dimensions and cropped top-left origin. Removable paper fill, viewport surround, and outer CSS frame are not baked into the images. Quran glyphs, Tajweed colors, diacritics, Ayah markers, source-semantic surah/basmala content, and page numbering remain. Quran words use \`WordKey = surah:ayah:position\`; Ayah markers, surah headings, and basmala remain explicitly classified without invented WordKeys. Multi-line Ayahs retain one union rectangle per rendered line. Exact edition verification is unproven and redistribution approval is unapproved.\n`
    : `# QPC V4 Tajweed 604-page research pack\n\n**RESEARCH ONLY — NOT FOR RELEASE**\n\n604 fixed transparent 8-bit indexed PNG rasters with deterministic 256-entry RGBA palettes and gzip-compressed geometry generated from pinned commit \`${COMMIT}\`. Removable paper fill, viewport surround, and outer CSS frame are not baked into the images. Quran glyphs, Tajweed colors, diacritics, Ayah markers, source-semantic surah/basmala content, and page numbering remain. Canonical coordinates are ${WIDTH} × ${HEIGHT} pixels with a top-left origin. Quran words use \`WordKey = surah:ayah:position\`; Ayah markers, surah headings, and basmala remain explicitly classified without invented WordKeys. Multi-line Ayahs retain one union rectangle per rendered line. Exact edition verification is unproven and redistribution approval is unapproved.\n`;
  fs.writeFileSync(path.join(packRoot, 'README_RESEARCH_ONLY.md'), readme);
}

function readValidPair(page, lines, validAyahs, imagePath = path.join(pagesRoot, `${stem(page)}.png`), geometryPath = path.join(geometryRoot, `${stem(page)}.json.gz`)) {
  if (!nonEmptyFile(imagePath) || !nonEmptyFile(geometryPath)) return null;
  try {
    const geometry = JSON.parse(zlib.gunzipSync(fs.readFileSync(geometryPath)).toString('utf8'));
    const counts = validateGeometryDocument(page, geometry, lines, validAyahs);
    validatePng(imagePath, page, geometry);
    return {
      imageBytes: fs.statSync(imagePath).size,
      geometryBytes: fs.statSync(geometryPath).size,
      words: counts.words,
      ayahLines: counts.ayahLines,
      width: geometry.viewport.width,
      height: geometry.viewport.height,
    };
  } catch (_) {
    return null;
  }
}

async function evaluateValue(browser, sessionId, page, phase, expression, awaitPromise = false) {
  const response = await boundedBrowserOperation(browser.connection.send('Runtime.evaluate', {
    expression,
    awaitPromise,
    returnByValue: true,
  }, sessionId), page, phase);
  if (response.exceptionDetails) {
    const detail = response.exceptionDetails.exception?.description ?? response.exceptionDetails.text ?? 'JavaScript evaluation failed';
    throw new InvariantError(`page ${page}: failed during ${phase}: ${detail}`);
  }
  return response.result?.value;
}

async function waitForPageReady(browser, sessionId, page) {
  const expression = `new Promise((resolve)=>{const finish=()=>resolve(window.__MAAB_QPC_STATE__||{phase:'DOCUMENT_READY',ready:false,error:'readiness state missing'});const state=window.__MAAB_QPC_STATE__;if(state&&(state.ready||state.phase==='ERROR'))finish();else window.addEventListener('maab-qpc-ready',finish,{once:true})})`;
  try {
    const state = await evaluateValue(browser, sessionId, page, 'PAGE_READY', expression, true);
    requireInvariant(state, `page ${page}: failed during DOM_READY: readiness state missing`);
    if (state.phase === 'ERROR') throw new InvariantError(`page ${page}: failed during ${state.failure_phase ?? 'DOM_READY'}: ${state.error}`);
    requireInvariant(state.ready === true && state.phase === 'READY', `page ${page}: failed during DOM_READY: invalid readiness state`);
  } catch (error) {
    if (!(error instanceof BrowserProcessError) || !error.message.includes('timed out')) throw error;
    let state = null;
    try {
      const response = await boundedBrowserOperation(browser.connection.send('Runtime.evaluate', { expression: 'window.__MAAB_QPC_STATE__', returnByValue: true }, sessionId), page, 'READINESS_DIAGNOSTIC', 1000);
      state = response.result?.value ?? null;
    } catch (_) { /* preserve the readiness timeout */ }
    const phase = state?.phase && state.phase !== 'ERROR' ? state.phase : state?.failure_phase ?? 'DOM_READY';
    throw new InvariantError(`page ${page}: timed out during ${phase} after ${BROWSER_TIMEOUT_MS}ms`);
  }
}

async function renderPage(browser, page, lines, validAyahs) {
  const pageWorkRoot = path.join(workRoot, `page-${stem(page)}`);
  fs.rmSync(pageWorkRoot, { recursive: true, force: true });
  ensureDirectory(pageWorkRoot);
  const renderPath = path.join(pageWorkRoot, `render-${stem(page)}.html`);
  const imagePath = path.join(pagesRoot, `${stem(page)}.png`);
  const geometryPath = path.join(geometryRoot, `${stem(page)}.json.gz`);
  const fullImage = path.join(pageWorkRoot, `${stem(page)}.full.png`);
  const rgbaImage = path.join(pageWorkRoot, `${stem(page)}.rgba.png`);
  const temporaryImage = path.join(pageWorkRoot, `${stem(page)}.tmp.png`);
  const temporaryGeometry = path.join(pageWorkRoot, `${stem(page)}.tmp.json.gz`);
  let targetId = null;
  try {
    fs.writeFileSync(renderPath, renderHtml(page, lines, validAyahs));
    const created = await boundedBrowserOperation(browser.connection.send('Target.createTarget', { url: 'about:blank' }), page, 'TARGET_CREATE');
    targetId = created.targetId;
    requireInvariant(targetId, `page ${page}: failed during TARGET_CREATE: target id missing`);
    const attached = await boundedBrowserOperation(browser.connection.send('Target.attachToTarget', { targetId, flatten: true }), page, 'TARGET_ATTACH');
    const sessionId = attached.sessionId;
    requireInvariant(sessionId, `page ${page}: failed during TARGET_ATTACH: session id missing`);
    await boundedBrowserOperation(Promise.all([
      browser.connection.send('Page.enable', {}, sessionId),
      browser.connection.send('Runtime.enable', {}, sessionId),
      browser.connection.send('Emulation.setDeviceMetricsOverride', { width: WIDTH, height: HEIGHT, deviceScaleFactor: SCALE, mobile: false }, sessionId),
      browser.connection.send('Emulation.setDefaultBackgroundColorOverride', { color: { r: 0, g: 0, b: 0, a: 0 } }, sessionId),
    ]), page, 'PAGE_SETUP');

    const loaded = browser.connection.waitForEvent('Page.loadEventFired', sessionId);
    const navigation = await boundedBrowserOperation(browser.connection.send('Page.navigate', { url: pathToFileURL(renderPath).href }, sessionId), page, 'NAVIGATION');
    requireInvariant(!navigation.errorText, `page ${page}: failed during NAVIGATION: ${navigation.errorText}`);
    await boundedBrowserOperation(loaded, page, 'NAVIGATION');
    await waitForPageReady(browser, sessionId, page);

    const renderResult = await evaluateValue(browser, sessionId, page, 'GEOMETRY_EXTRACTION', 'window.__MAAB_QPC_RESULT__', false);
    requireInvariant(renderResult?.ready === true, `page ${page}: failed during GEOMETRY_EXTRACTION: render result missing`);
    requireInvariant(renderResult.font_status?.length && renderResult.font_status.every((entry) => entry.loaded), `page ${page}: failed during FONT_READY: required font/resource load failed`);
    requireInvariant(renderResult.clipped === false, `page ${page}: failed during DOM_READY: visible clipping signal detected`);
    const fullGeometry = geometryFor(page, lines, renderResult, validAyahs);
    const fullScreenshot = await boundedBrowserOperation(browser.connection.send('Page.captureScreenshot', {
      format: 'png',
      fromSurface: true,
      captureBeyondViewport: false,
      clip: { x: 0, y: 0, width: WIDTH, height: HEIGHT, scale: 1 },
    }, sessionId), page, 'FULL_SCREENSHOT');
    requireInvariant(typeof fullScreenshot.data === 'string' && fullScreenshot.data.length > 0, `page ${page}: failed during FULL_SCREENSHOT: PNG data missing`);
    fs.writeFileSync(fullImage, Buffer.from(fullScreenshot.data, 'base64'));
    const fullDecoded = decodeTransparentPng(fullImage, page, WIDTH, HEIGHT);
    const crop = activeLayout
      ? visiblePixelBounds(fullDecoded, page)
      : { x: 0, y: 0, width: WIDTH, height: HEIGHT };
    const geometry = activeLayout
      ? cropPhoneNativeGeometry(fullGeometry, crop)
      : fullGeometry;
    const screenshot = activeLayout
      ? await boundedBrowserOperation(browser.connection.send('Page.captureScreenshot', {
        format: 'png',
        fromSurface: true,
        captureBeyondViewport: false,
        clip: { ...crop, scale: 1 },
      }, sessionId), page, 'CROPPED_SCREENSHOT')
      : fullScreenshot;
    requireInvariant(typeof screenshot.data === 'string' && screenshot.data.length > 0, `page ${page}: failed during SCREENSHOT: PNG data missing`);
    fs.writeFileSync(rgbaImage, Buffer.from(screenshot.data, 'base64'));
    const rgba = decodeTransparentPng(
      rgbaImage,
      page,
      geometry.viewport.width,
      geometry.viewport.height,
    );
    requireInvariant(rgba.colorType === 6, `page ${page}: browser screenshot is not RGBA`);
    encodeIndexedPng(rgba, temporaryImage, page);
    fs.writeFileSync(temporaryGeometry, zlib.gzipSync(Buffer.from(`${JSON.stringify(geometry)}\n`), { level: 9, mtime: 0 }));
    const validated = readValidPair(page, lines, validAyahs, temporaryImage, temporaryGeometry);
    requireInvariant(validated, `page ${page}: failed during OUTPUT_VALIDATION: temporary image/geometry pair is invalid`);
    fs.renameSync(temporaryGeometry, geometryPath);
    fs.renameSync(temporaryImage, imagePath);
    return validated;
  } finally {
    if (targetId) {
      try { await boundedBrowserOperation(browser.connection.send('Target.closeTarget', { targetId }), page, 'TARGET_CLOSE'); } catch (_) { /* browser shutdown also disposes the isolated target */ }
    }
    try { fs.rmSync(pageWorkRoot, { recursive: true, force: true }); } catch (_) { /* isolated leftovers are safe to clean on the next attempt */ }
  }
}

function collectValidPack(prepared, validAyahs) {
  const totals = { completePages: 0, pages: [], pageDimensions: {}, imageBytes: 0, geometryBytes: 0, words: 0, ayahLines: 0 };
  const pages = Array.from({ length: PAGE_COUNT }, (_, index) => index + 1);
  for (const page of pages) {
    const valid = readValidPair(page, prepared.pages.get(page), validAyahs);
    if (!valid) continue;
    totals.completePages += 1;
    totals.pages.push(page);
    totals.pageDimensions[page] = { width: valid.width, height: valid.height };
    totals.imageBytes += valid.imageBytes;
    totals.geometryBytes += valid.geometryBytes;
    totals.words += valid.words;
    totals.ayahLines += valid.ayahLines;
  }
  return totals;
}

function writeManifest(totals) {
  if (activeLayout) {
    const manifest = {
      pack_id: 'maab.qpc_v4_tajweed.research.v1',
      research_only: true,
      production_approved: false,
      layout: activeLayout.name,
      pages_generated: totals.pages,
      page_count: totals.completePages,
      source: { repository: REPOSITORY, pinned_commit: COMMIT },
      visual_backend: 'QPC V4 Tajweed transparent Quran content raster',
      canonical_width: WIDTH,
      canonical_height: HEIGHT,
      source_canvas_width: WIDTH,
      source_canvas_height: HEIGHT,
      variable_page_dimensions: true,
      page_dimensions: totals.pageDimensions,
      target_content_top: activeLayout.targetContentTop,
      target_content_bottom: activeLayout.targetContentBottom,
      device_scale_factor: SCALE,
      image_format: 'png',
      png_color_type: 'indexed',
      png_bit_depth: 8,
      palette_entries: PNG_PALETTE_SIZE,
      palette_quantizer: 'semantic-reserved-weighted-median-cut-rgba-v1',
      alpha_mode: 'palette-trns-transparent',
      removable_paper_background_baked: false,
      removable_outer_frame_baked: false,
      render_fingerprint: RENDER_FINGERPRINT,
      word_geometry_present: true,
      ayah_geometry_present: true,
      visual_block_geometry_present: true,
      edition_verification_status: 'unproven',
      redistribution_approval_status: 'unapproved',
      total_image_bytes: totals.imageBytes,
      total_geometry_bytes: totals.geometryBytes,
      generator_version: VERSION,
      schema_version: SCHEMA,
      geometry_schema: { coordinates: 'canonical pixels; top-left origin', word_key: 'surah:ayah:position', ayah_key: 'surah:ayah', ayah_regions: 'per-line unions of Quran word rectangles', block_transform: 'DOM-owned full-row Y translation only', non_word_policy: 'ayah markers, surah headings, and basmala are classified without invented WordKeys' },
    };
    const destination = path.join(packRoot, 'manifest.json');
    const temporary = path.join(packRoot, `.manifest.${process.pid}.tmp.json`);
    fs.writeFileSync(temporary, `${JSON.stringify(manifest, null, 2)}\n`);
    fs.renameSync(temporary, destination);
    fs.rmSync(path.join(workRoot, 'manifest.phone-native.previous.json'), { force: true });
    return;
  }
  const manifest = {
    pack_id: 'maab.qpc_v4_tajweed.research.v1', research_only: true, production_approved: false,
    riwayah: 'hafs', page_count: PAGE_COUNT,
    source: { repository: REPOSITORY, pinned_commit: COMMIT },
    visual_backend: 'QPC V4 Tajweed transparent Quran content raster', canonical_width: WIDTH, canonical_height: HEIGHT,
    device_scale_factor: SCALE, image_format: 'png', png_color_type: 'indexed', png_bit_depth: 8,
    palette_entries: PNG_PALETTE_SIZE, palette_quantizer: 'semantic-reserved-weighted-median-cut-rgba-v1',
    alpha_mode: 'palette-trns-transparent', removable_paper_background_baked: false,
    removable_outer_frame_baked: false, render_fingerprint: RENDER_FINGERPRINT, word_geometry_present: true, ayah_geometry_present: true,
    edition_verification_status: 'unproven', redistribution_approval_status: 'unapproved',
    total_image_bytes: totals.imageBytes, total_geometry_bytes: totals.geometryBytes,
    generator_version: VERSION, schema_version: SCHEMA,
    geometry_schema: { coordinates: 'canonical pixels; top-left origin', word_key: 'surah:ayah:position', ayah_key: 'surah:ayah', ayah_regions: 'per-line unions of Quran word rectangles', non_word_policy: 'ayah markers, surah headings, and basmala are classified without invented WordKeys' },
  };
  const destination = path.join(packRoot, 'manifest.json');
  const temporary = path.join(packRoot, `.manifest.${process.pid}.tmp.json`);
  fs.writeFileSync(temporary, `${JSON.stringify(manifest, null, 2)}\n`);
  fs.renameSync(temporary, destination);
  fs.rmSync(path.join(workRoot, 'manifest.previous.json'), { force: true });
}

async function main() {
  const started = process.hrtime.bigint();
  requireInvariant(Number(process.versions.node.split('.')[0]) >= 22, 'Node.js 22 or newer is required');
  const range = parseArguments(process.argv.slice(2));
  configureLayout(range.layout);
  const browserExecutable = locateChrome();
  await ensurePinnedSourceCache();
  const source = loadSource(), prepared = prepare(source);
  initializeOutput();
  let generated = 0, reused = 0;
  let browser = null;
  try {
    for (const page of range.pages) {
      const valid = readValidPair(page, prepared.pages.get(page), source.validAyahs);
      if (valid) {
        reused += 1;
        process.stdout.write(`[${stem(page)}/${PAGE_COUNT}] skipped (valid)\n`);
        continue;
      }
      if (!browser) browser = await launchCdpBrowser(browserExecutable);
      await renderPage(browser, page, prepared.pages.get(page), source.validAyahs);
      generated += 1;
      process.stdout.write(`[${stem(page)}/${PAGE_COUNT}] generated\n`);
    }
  } finally {
    if (browser) await closeCdpBrowser(browser);
  }
  const totals = collectValidPack(prepared, source.validAyahs);
  if (totals.completePages === PAGE_COUNT) {
    requireInvariant(totals.words === prepared.quranWordCount, `word region total ${totals.words} differs from source ${prepared.quranWordCount}`);
    writeManifest(totals);
  }
  const elapsed = Number(process.hrtime.bigint() - started) / 1e9;
  process.stdout.write(`generated this run: ${generated}\nreused valid pages: ${reused}\npages complete: ${totals.completePages}\nword regions: ${totals.words}\nayah line regions: ${totals.ayahLines}\nimage bytes: ${totals.imageBytes}\ngeometry bytes: ${totals.geometryBytes}\ntotal pack bytes: ${totals.imageBytes + totals.geometryBytes}\nelapsed: ${elapsed.toFixed(1)}s\n`);
}

main().catch((error) => {
  process.stderr.write(`${error instanceof InvariantError ? 'INVARIANT FAILURE' : 'GENERATOR FAILURE'}: ${error.message}\n`);
  process.exitCode = 1;
});
