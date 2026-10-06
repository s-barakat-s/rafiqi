abstract final class QuranCoreSchema {
  static const version = 1;

  static final statements = <String>[
    '''CREATE TABLE quran_metadata (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      source_provider TEXT NOT NULL, source_resource_name TEXT NOT NULL,
      source_reference TEXT NOT NULL, source_version TEXT NOT NULL,
      source_acquired_at TEXT NOT NULL, source_checksum TEXT NOT NULL,
      schema_version INTEGER NOT NULL, ingestion_tool_version TEXT NOT NULL,
      license_or_usage_reference TEXT NOT NULL, attribution_notes TEXT NOT NULL,
      expected_surah_count INTEGER NOT NULL, expected_ayah_count INTEGER NOT NULL,
      dataset_kind TEXT NOT NULL
    )''',
    '''CREATE TABLE surahs (
      number INTEGER PRIMARY KEY CHECK(number BETWEEN 1 AND 114),
      name_arabic TEXT NOT NULL CHECK(length(trim(name_arabic)) > 0),
      ayah_count INTEGER NOT NULL CHECK(ayah_count > 0)
    )''',
    '''CREATE TABLE ayahs (
      surah_number INTEGER NOT NULL, ayah_number INTEGER NOT NULL CHECK(ayah_number > 0),
      global_index INTEGER NOT NULL UNIQUE CHECK(global_index > 0),
      text_uthmani TEXT NOT NULL CHECK(length(trim(text_uthmani)) > 0),
      text_search TEXT,
      PRIMARY KEY(surah_number, ayah_number),
      FOREIGN KEY(surah_number) REFERENCES surahs(number)
    )''',
    'CREATE INDEX ayahs_surah_order ON ayahs(surah_number, ayah_number)',
    'CREATE INDEX ayahs_global_order ON ayahs(global_index)',
    _boundary('juz_boundaries'),
    _boundary('hizb_boundaries'),
    _boundary('rub_el_hizb_boundaries'),
    '''CREATE TABLE sajdah_markers (
      id INTEGER PRIMARY KEY, surah_number INTEGER NOT NULL, ayah_number INTEGER NOT NULL,
      kind TEXT NOT NULL CHECK(length(trim(kind)) > 0),
      UNIQUE(surah_number, ayah_number),
      FOREIGN KEY(surah_number, ayah_number) REFERENCES ayahs(surah_number, ayah_number)
    )''',
  ];

  static String _boundary(String table) => '''CREATE TABLE $table (
    number INTEGER PRIMARY KEY CHECK(number > 0),
    surah_number INTEGER NOT NULL, ayah_number INTEGER NOT NULL,
    FOREIGN KEY(surah_number, ayah_number) REFERENCES ayahs(surah_number, ayah_number)
  )''';
}
