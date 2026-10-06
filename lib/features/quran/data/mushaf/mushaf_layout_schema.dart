abstract final class MushafLayoutSchema {
  static const version = 1;
  static const statements = <String>[
    '''CREATE TABLE layout_metadata (
      id INTEGER PRIMARY KEY CHECK(id = 1), mushaf_id TEXT NOT NULL,
      display_name TEXT NOT NULL, internal_name TEXT NOT NULL,
      riwayah_id TEXT NOT NULL, edition_version TEXT NOT NULL,
      page_count INTEGER NOT NULL CHECK(page_count > 0),
      nominal_lines_per_page INTEGER NOT NULL CHECK(nominal_lines_per_page > 0),
      render_strategy TEXT NOT NULL, layout_resource_id TEXT NOT NULL,
      script_resource_id TEXT NOT NULL, font_resource_id TEXT,
      schema_version INTEGER NOT NULL,
      resource_id TEXT NOT NULL, resource_type TEXT NOT NULL,
      provider TEXT NOT NULL, source_reference TEXT NOT NULL,
      resource_version TEXT NOT NULL, acquired_at TEXT NOT NULL,
      source_checksum TEXT NOT NULL, license_reference TEXT NOT NULL,
      commercial_use_status TEXT NOT NULL, redistribution_status TEXT NOT NULL,
      attribution TEXT NOT NULL, production_approval_status TEXT NOT NULL,
      quran_core_versions TEXT NOT NULL
    )''',
    '''CREATE TABLE pages (
      page_number INTEGER PRIMARY KEY CHECK(page_number > 0)
    )''',
    '''CREATE TABLE lines (
      page_number INTEGER NOT NULL, line_number INTEGER NOT NULL CHECK(line_number > 0),
      line_type TEXT NOT NULL, alignment TEXT,
      first_surah INTEGER, first_ayah INTEGER, first_word INTEGER,
      last_surah INTEGER, last_ayah INTEGER, last_word INTEGER,
      PRIMARY KEY(page_number, line_number),
      FOREIGN KEY(page_number) REFERENCES pages(page_number)
    )''',
    '''CREATE TABLE word_placements (
      page_number INTEGER NOT NULL, line_number INTEGER NOT NULL,
      position_in_line INTEGER NOT NULL CHECK(position_in_line > 0),
      surah_number INTEGER NOT NULL, ayah_number INTEGER NOT NULL, word_number INTEGER NOT NULL,
      glyph_code TEXT, provider TEXT, provider_word_id TEXT, provider_resource_version TEXT,
      PRIMARY KEY(page_number, line_number, position_in_line),
      UNIQUE(surah_number, ayah_number, word_number),
      FOREIGN KEY(page_number, line_number) REFERENCES lines(page_number, line_number)
    )''',
    'CREATE INDEX placements_ayah ON word_placements(surah_number, ayah_number, page_number, line_number, position_in_line)',
    'CREATE INDEX placements_word ON word_placements(surah_number, ayah_number, word_number)',
    '''CREATE TABLE word_provider_mappings (
      provider TEXT NOT NULL, resource_version TEXT NOT NULL, provider_word_id TEXT NOT NULL,
      surah_number INTEGER NOT NULL, ayah_number INTEGER NOT NULL, word_number INTEGER NOT NULL,
      PRIMARY KEY(provider, resource_version, provider_word_id),
      UNIQUE(provider, resource_version, surah_number, ayah_number, word_number),
      FOREIGN KEY(surah_number, ayah_number, word_number)
        REFERENCES word_placements(surah_number, ayah_number, word_number)
    )''',
  ];
}
