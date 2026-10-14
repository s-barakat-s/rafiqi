import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:tasbeh/features/quran/data/quran_core_schema.dart';

abstract final class QuranCoreDatabaseVerifier {
  static Future<void> verify(Database database) async {
    final integrity = await database.rawQuery('PRAGMA integrity_check');
    if (integrity.length != 1 || integrity.single.values.single != 'ok') {
      throw StateError('Quran Core SQLite integrity check failed');
    }
    final foreignKeys = await database.rawQuery('PRAGMA foreign_key_check');
    if (foreignKeys.isNotEmpty) {
      throw StateError('Quran Core foreign key check failed');
    }
    final metadata = await database.query('quran_metadata');
    if (metadata.length != 1 ||
        metadata.single['schema_version'] != QuranCoreSchema.version) {
      throw StateError('Unsupported or missing Quran Core metadata');
    }
    final surahCount = firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM surahs'),
    );
    final ayahCount = firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM ayahs'),
    );
    final searchCount = firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM ayah_search_documents'),
    );
    if (surahCount != metadata.single['expected_surah_count'] ||
        ayahCount != metadata.single['expected_ayah_count'] ||
        searchCount != ayahCount) {
      throw StateError('Quran Core declared counts do not match database');
    }
  }
}
