'use strict';

const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const test = require('node:test');

const {
  COMMIT,
  REPOSITORY,
  SourceValidationError,
  buildResearchDataset,
  serializeDataset,
} = require('./build_qpc_research_core.js');

const expectations = Object.freeze({
  sourceRows: 8,
  wordTokens: 5,
  markers: 3,
  surahs: 2,
  ayahs: 3,
});

const csv = [
  'id,location,surah,ayah,word,text',
  '1,1:1:1,1,1,1,بِسۡمِ',
  '2,1:1:2,1,1,2,ٱللَّهِ',
  '3,1:1:3,1,1,3,١',
  '4,1:2:1,1,2,1,قُلۡ',
  '5,1:2:2,1,2,2,2',
  '6,2:1:1,2,1,1,هُوَ',
  '7,2:1:2,2,1,2,ٱللَّهُ',
  '8,2:1:3,2,1,3,٣',
  '',
].join('\n');

function inputs(source = csv, catalog = { names_arabic: ['الفاتحة', 'الإخلاص'], ayah_counts: [2, 1] }) {
  const wordsBytes = Buffer.from(source, 'utf8');
  return {
    wordsBytes,
    catalog,
    sourceManifest: {
      repository: REPOSITORY,
      commit: COMMIT,
      archive_sha256: 'a'.repeat(64),
      files: [{
        path: 'data/words.csv',
        bytes: wordsBytes.length,
        sha256: crypto.createHash('sha256').update(wordsBytes).digest('hex'),
      }],
    },
    expectations,
  };
}

test('preserves Quran tokens, joins with U+0020, and excludes numeric markers', () => {
  const dataset = buildResearchDataset(inputs());
  assert.equal(dataset.metadata.dataset_kind, 'research');
  assert.equal(dataset.metadata.source_acquired_at, 'unavailable');
  assert.equal(dataset.ayahs[0].text_uthmani, 'بِسۡمِ ٱللَّهِ');
  assert.equal(dataset.ayahs[1].text_uthmani, 'قُلۡ');
  assert.equal(dataset.ayahs[2].text_uthmani, 'هُوَ ٱللَّهُ');
  assert.deepEqual(dataset.ayahs.map((ayah) => ayah.global_index), [1, 2, 3]);
  assert.deepEqual(dataset.juz_boundaries, []);
  assert.deepEqual(dataset.hizb_boundaries, []);
  assert.deepEqual(dataset.rub_el_hizb_boundaries, []);
  assert.deepEqual(dataset.sajdah_markers, []);
});

test('rejects malformed locations', () => {
  const malformed = csv.replace('1,1:1:1,1,1,1,', '1,1:1:9,1,1,1,');
  assert.throws(() => buildResearchDataset(inputs(malformed)), SourceValidationError);
});

test('rejects duplicate or non-contiguous IDs', () => {
  const duplicate = csv.replace('4,1:2:1', '3,1:2:1');
  assert.throws(() => buildResearchDataset(inputs(duplicate)), /unique and contiguous/);
});

test('rejects missing Ayahs', () => {
  const missing = csv
    .replace('4,1:2:1,1,2,1,', '4,2:1:4,2,1,4,')
    .replace('5,1:2:2,1,2,2,', '5,2:1:5,2,1,5,');
  assert.throws(() => buildResearchDataset(inputs(missing)), /Missing Ayah 1:2/);
});

test('rejects incorrect Surah catalog counts', () => {
  assert.throws(
    () => buildResearchDataset(inputs(csv, { names_arabic: ['الفاتحة'], ayah_counts: [3] })),
    /Expected 2 Surah names/,
  );
});

test('rejects a missing source row rather than repairing it', () => {
  const missingRow = csv.split('\n').filter((line) => !line.startsWith('7,')).join('\n');
  assert.throws(() => buildResearchDataset(inputs(missingRow)), /Expected 8 source rows/);
});

test('serialization is byte deterministic', () => {
  const first = Buffer.from(serializeDataset(buildResearchDataset(inputs())));
  const second = Buffer.from(serializeDataset(buildResearchDataset(inputs())));
  assert.deepEqual(second, first);
});
