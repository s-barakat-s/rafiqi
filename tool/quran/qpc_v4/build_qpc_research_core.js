'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const REPOSITORY = 'https://github.com/hussainsajib/qpc-v4-mushaf-bundle';
const COMMIT = 'f84ccb5688d5404748a0d38e6c53e09df4469ec9';
const EXPECTED = Object.freeze({
  sourceRows: 83668,
  wordTokens: 77432,
  markers: 6236,
  surahs: 114,
  ayahs: 6236,
});
const MARKER_PATTERN = /^\p{Nd}+$/u;

class SourceValidationError extends Error {}

function parseCsv(source) {
  const rows = [];
  let row = [];
  let field = '';
  let quoted = false;
  for (let index = 0; index < source.length; index += 1) {
    const character = source[index];
    if (quoted) {
      if (character === '"' && source[index + 1] === '"') {
        field += '"';
        index += 1;
      } else if (character === '"') {
        quoted = false;
      } else {
        field += character;
      }
    } else if (character === '"') {
      quoted = true;
    } else if (character === ',') {
      row.push(field);
      field = '';
    } else if (character === '\n') {
      row.push(field.endsWith('\r') ? field.slice(0, -1) : field);
      rows.push(row);
      row = [];
      field = '';
    } else {
      field += character;
    }
  }
  if (quoted) throw new SourceValidationError('Unterminated quoted CSV field');
  if (field.length > 0 || row.length > 0) {
    row.push(field.endsWith('\r') ? field.slice(0, -1) : field);
    rows.push(row);
  }
  return rows;
}

function integer(value, label) {
  if (!/^[1-9]\d*$/.test(value)) {
    throw new SourceValidationError(`${label} must be a positive integer`);
  }
  return Number(value);
}

function sha256(bytes) {
  return crypto.createHash('sha256').update(bytes).digest('hex');
}

function assert(condition, message) {
  if (!condition) throw new SourceValidationError(message);
}

function validateSourceManifest(manifest, wordsBytes) {
  assert(manifest && typeof manifest === 'object', 'Source cache manifest is invalid');
  assert(manifest.repository === REPOSITORY, 'Unexpected source repository');
  assert(manifest.commit === COMMIT, 'Unexpected source commit');
  assert(/^[a-f0-9]{64}$/.test(manifest.archive_sha256), 'Invalid source archive checksum');
  const wordsEntry = Array.isArray(manifest.files)
    ? manifest.files.find((entry) => entry.path === 'data/words.csv')
    : null;
  assert(wordsEntry, 'Source cache manifest does not describe data/words.csv');
  assert(wordsEntry.bytes === wordsBytes.length, 'words.csv byte count does not match cache manifest');
  assert(wordsEntry.sha256 === sha256(wordsBytes), 'words.csv checksum does not match cache manifest');
}

function validateCatalog(catalog, expected) {
  assert(catalog && typeof catalog === 'object', 'Surah metadata must be an object');
  assert(Array.isArray(catalog.names_arabic), 'names_arabic must be an array');
  assert(Array.isArray(catalog.ayah_counts), 'ayah_counts must be an array');
  assert(catalog.names_arabic.length === expected.surahs, `Expected ${expected.surahs} Surah names`);
  assert(catalog.ayah_counts.length === expected.surahs, `Expected ${expected.surahs} Surah counts`);
  let total = 0;
  for (let index = 0; index < expected.surahs; index += 1) {
    const name = catalog.names_arabic[index];
    const count = catalog.ayah_counts[index];
    assert(typeof name === 'string' && name.trim().length > 0, `Surah ${index + 1} has no name`);
    assert(Number.isInteger(count) && count > 0, `Surah ${index + 1} has an invalid Ayah count`);
    total += count;
  }
  assert(total === expected.ayahs, `Expected ${expected.ayahs} catalog Ayahs, found ${total}`);
}

function buildResearchDataset({
  wordsBytes,
  catalog,
  sourceManifest,
  expectations = EXPECTED,
  licenseReference = `quran_resources/.cache/qpc_v4_source/${COMMIT}/LICENSE-NOTICE.md`,
}) {
  validateSourceManifest(sourceManifest, wordsBytes);
  validateCatalog(catalog, expectations);
  const rows = parseCsv(wordsBytes.toString('utf8'));
  assert(rows.length > 0, 'words.csv is empty');
  assert(
    JSON.stringify(rows[0]) === JSON.stringify(['id', 'location', 'surah', 'ayah', 'word', 'text']),
    'words.csv headers do not match the pinned contract',
  );
  const records = rows.slice(1);
  assert(records.length === expectations.sourceRows, `Expected ${expectations.sourceRows} source rows, found ${records.length}`);

  const groups = new Map();
  let wordTokens = 0;
  let markers = 0;
  for (let index = 0; index < records.length; index += 1) {
    const row = records[index];
    assert(row.length === 6, `Source row ${index + 2} must contain six fields`);
    const id = integer(row[0], `Source row ${index + 2} id`);
    assert(id === index + 1, `Source IDs must be unique and contiguous; expected ${index + 1}, found ${id}`);
    const surah = integer(row[2], `Source row ${id} surah`);
    const ayah = integer(row[3], `Source row ${id} ayah`);
    const position = integer(row[4], `Source row ${id} word`);
    assert(row[1] === `${surah}:${ayah}:${position}`, `Source row ${id} location mismatch`);
    assert(surah <= expectations.surahs, `Source row ${id} has unknown Surah ${surah}`);
    assert(ayah <= catalog.ayah_counts[surah - 1], `Source row ${id} has unknown Ayah ${surah}:${ayah}`);
    const key = `${surah}:${ayah}`;
    const group = groups.get(key) || { tokens: [], positions: [], markers: 0 };
    assert(!group.positions.includes(position), `Duplicate source location ${row[1]}`);
    group.positions.push(position);
    if (MARKER_PATTERN.test(row[5].trim())) {
      group.markers += 1;
      markers += 1;
    } else {
      assert(row[5].length > 0, `Source row ${id} has empty Quran text`);
      assert(row[5] === row[5].trim(), `Source row ${id} Quran token has surrounding whitespace`);
      group.tokens.push(row[5]);
      wordTokens += 1;
    }
    groups.set(key, group);
  }
  assert(wordTokens === expectations.wordTokens, `Expected ${expectations.wordTokens} Quran word rows, found ${wordTokens}`);
  assert(markers === expectations.markers, `Expected ${expectations.markers} marker rows, found ${markers}`);

  const surahs = [];
  const ayahs = [];
  let globalIndex = 0;
  for (let surah = 1; surah <= expectations.surahs; surah += 1) {
    const ayahCount = catalog.ayah_counts[surah - 1];
    surahs.push({ number: surah, name_arabic: catalog.names_arabic[surah - 1], ayah_count: ayahCount });
    for (let ayah = 1; ayah <= ayahCount; ayah += 1) {
      const key = `${surah}:${ayah}`;
      const group = groups.get(key);
      assert(group, `Missing Ayah ${key}`);
      assert(group.tokens.length > 0, `Ayah ${key} has no Quran word tokens`);
      assert(group.markers === 1, `Ayah ${key} must have exactly one numeric marker`);
      for (let position = 1; position <= group.positions.length; position += 1) {
        assert(group.positions[position - 1] === position, `Ayah ${key} has missing or unordered word position ${position}`);
      }
      globalIndex += 1;
      ayahs.push({
        surah_number: surah,
        ayah_number: ayah,
        global_index: globalIndex,
        text_uthmani: group.tokens.join(' '),
      });
    }
  }
  assert(groups.size === expectations.ayahs, `Expected ${expectations.ayahs} unique Ayah keys, found ${groups.size}`);
  assert(globalIndex === expectations.ayahs, `Expected ${expectations.ayahs} generated Ayahs, found ${globalIndex}`);

  return {
    metadata: {
      source_provider: 'QPC V4 Mushaf Bundle (research source cache)',
      source_resource_name: 'QPC V4 words.csv Unicode tokens',
      source_reference: sourceManifest.repository,
      source_version: sourceManifest.commit,
      source_acquired_at: 'unavailable',
      schema_version: 2,
      ingestion_tool_version: 'maab-quran-core-ingestion/2',
      license_or_usage_reference: licenseReference,
      attribution_notes: `Research only; generated from pinned source archive SHA-256 ${sourceManifest.archive_sha256}. Exact edition authentication and redistribution approval are unproven. Ayah text joins preserved source tokens with U+0020.`,
      expected_surah_count: expectations.surahs,
      expected_ayah_count: expectations.ayahs,
      dataset_kind: 'research',
    },
    surahs,
    ayahs,
    juz_boundaries: [],
    hizb_boundaries: [],
    rub_el_hizb_boundaries: [],
    sajdah_markers: [],
  };
}

function serializeDataset(dataset) {
  return `${JSON.stringify(dataset, null, 2)}\n`;
}

function writeIfChanged(outputPath, bytes) {
  if (fs.existsSync(outputPath) && fs.readFileSync(outputPath).equals(bytes)) return false;
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  const staging = `${outputPath}.staging`;
  fs.writeFileSync(staging, bytes);
  fs.renameSync(staging, outputPath);
  return true;
}

function generate(options = {}) {
  const repositoryRoot = options.repositoryRoot || path.resolve(__dirname, '..', '..', '..');
  const cacheRoot = options.cacheRoot || path.join(repositoryRoot, 'quran_resources', '.cache', 'qpc_v4_source', COMMIT);
  const wordsPath = options.wordsPath || path.join(cacheRoot, 'data', 'words.csv');
  const catalogPath = options.catalogPath || path.join(repositoryRoot, 'assets', 'data', 'quran', 'qpc_v4_surah_metadata.json');
  const manifestPath = options.manifestPath || path.join(cacheRoot, 'source-cache.json');
  const outputPath = options.outputPath || path.join(repositoryRoot, 'quran_resources', 'qpc_research_core', 'quran_core_source.json');
  const wordsBytes = fs.readFileSync(wordsPath);
  const dataset = buildResearchDataset({
    wordsBytes,
    catalog: JSON.parse(fs.readFileSync(catalogPath, 'utf8')),
    sourceManifest: JSON.parse(fs.readFileSync(manifestPath, 'utf8')),
    expectations: options.expectations || EXPECTED,
    licenseReference: options.licenseReference,
  });
  const bytes = Buffer.from(serializeDataset(dataset), 'utf8');
  return {
    outputPath,
    changed: writeIfChanged(outputPath, bytes),
    sha256: sha256(bytes),
    bytes: bytes.length,
    sourceRows: wordsBytes.toString('utf8').split(/\r?\n/).filter(Boolean).length - 1,
    wordTokens: options.expectations?.wordTokens || EXPECTED.wordTokens,
    markers: options.expectations?.markers || EXPECTED.markers,
    surahs: dataset.surahs.length,
    ayahs: dataset.ayahs.length,
  };
}

if (require.main === module) {
  try {
    process.stdout.write(`${JSON.stringify(generate(), null, 2)}\n`);
  } catch (error) {
    process.stderr.write(`${error.stack || error}\n`);
    process.exitCode = 1;
  }
}

module.exports = {
  COMMIT,
  EXPECTED,
  MARKER_PATTERN,
  REPOSITORY,
  SourceValidationError,
  buildResearchDataset,
  generate,
  parseCsv,
  serializeDataset,
};
