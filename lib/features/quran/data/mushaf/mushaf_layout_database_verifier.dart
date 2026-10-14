import 'package:sqflite_common/sqlite_api.dart';
import 'package:tasbeh/features/quran/data/mushaf/mushaf_layout_schema.dart';

abstract final class MushafLayoutDatabaseVerifier {
  static Future<void> verify(Database database) async {
    final integrity = await database.rawQuery('PRAGMA integrity_check');
    if (integrity.length != 1 || integrity.single.values.single != 'ok') {
      throw StateError('Mushaf layout SQLite integrity check failed');
    }
    if ((await database.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
      throw StateError('Mushaf layout foreign key check failed');
    }
    final metadata = await database.query('layout_metadata');
    if (metadata.length != 1 ||
        metadata.single['schema_version'] != MushafLayoutSchema.version) {
      throw StateError('Unsupported or missing Mushaf layout metadata');
    }
    final pageRows = await database.rawQuery('SELECT COUNT(*) FROM pages');
    final pages = pageRows.single.values.single as int;
    if (pages != metadata.single['page_count']) {
      throw StateError('Mushaf page count mismatch');
    }
  }
}
