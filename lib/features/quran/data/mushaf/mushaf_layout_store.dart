import 'package:sqflite/sqflite.dart';
import 'package:tasbeh/features/quran/data/mushaf/mushaf_layout_schema.dart';
import 'package:tasbeh/features/quran/data/mushaf/sqflite_mushaf_layout_repository.dart';
import 'package:tasbeh/features/quran/domain/repositories/mushaf_layout_repository.dart';

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
    final pages = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM pages'),
    );
    if (pages != metadata.single['page_count']) {
      throw StateError('Mushaf page count mismatch');
    }
  }
}

final class MushafLayoutStore {
  MushafLayoutStore({DatabaseFactory? databaseFactory})
    : _factory = databaseFactory ?? databaseFactorySqflitePlugin;

  final DatabaseFactory _factory;
  Database? _database;
  Future<MushafLayoutRepository>? _initialization;

  Future<MushafLayoutRepository> initialize(String databasePath) =>
      _initialization ??= _open(databasePath);

  Future<MushafLayoutRepository> _open(String path) async {
    final database = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: true),
    );
    try {
      await MushafLayoutDatabaseVerifier.verify(database);
    } catch (_) {
      await database.close();
      rethrow;
    }
    _database = database;
    return SqfliteMushafLayoutRepository(database);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _initialization = null;
  }
}
