import 'package:sqflite/sqflite.dart';
import 'package:tasbeh/features/quran/data/mushaf/mushaf_layout_database_verifier.dart';
import 'package:tasbeh/features/quran/data/mushaf/sqflite_mushaf_layout_repository.dart';
import 'package:tasbeh/features/quran/domain/repositories/mushaf_layout_repository.dart';

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
