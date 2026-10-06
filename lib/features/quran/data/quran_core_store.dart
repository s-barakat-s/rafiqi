import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:tasbeh/features/quran/data/quran_core_schema.dart';
import 'package:tasbeh/features/quran/data/sqflite_quran_repository.dart';
import 'package:tasbeh/features/quran/domain/repositories/quran_repository.dart';

final class QuranCoreArtifact {
  const QuranCoreArtifact({
    required this.assetPath,
    required this.sha256Checksum,
    required this.contentVersion,
  });
  final String assetPath;
  final String sha256Checksum;
  final String contentVersion;
}

abstract interface class QuranCoreInstaller {
  Future<File> install(QuranCoreArtifact artifact);
}

final class QuranCoreAssetInstaller implements QuranCoreInstaller {
  const QuranCoreAssetInstaller({
    required this.assetBundle,
    required this.directory,
  });
  final AssetBundle assetBundle;
  final Directory directory;

  @override
  Future<File> install(QuranCoreArtifact artifact) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(artifact.sha256Checksum)) {
      throw ArgumentError.value(artifact.sha256Checksum, 'sha256Checksum');
    }
    await directory.create(recursive: true);
    final safeVersion = artifact.contentVersion.replaceAll(
      RegExp('[^a-zA-Z0-9._-]'),
      '_',
    );
    final target = File(
      p.join(
        directory.path,
        'quran_core_${safeVersion}_${artifact.sha256Checksum.substring(0, 12)}.db',
      ),
    );
    if (await target.exists() &&
        await _checksum(target) == artifact.sha256Checksum) {
      return target;
    }

    final data = await assetBundle.load(artifact.assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    if (sha256.convert(bytes).toString() != artifact.sha256Checksum) {
      throw const FormatException('Bundled Quran Core checksum mismatch');
    }
    final staging = File('${target.path}.staging');
    if (await staging.exists()) await staging.delete();
    await staging.writeAsBytes(bytes, flush: true);
    if (await _checksum(staging) != artifact.sha256Checksum) {
      await staging.delete();
      throw const FormatException('Staged Quran Core checksum mismatch');
    }
    if (await target.exists()) await target.delete();
    return staging.rename(target.path);
  }

  static Future<String> _checksum(File file) => file
      .openRead()
      .transform(sha256)
      .first
      .then((digest) => digest.toString());
}

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
    final surahCount = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM surahs'),
    );
    final ayahCount = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM ayahs'),
    );
    if (surahCount != metadata.single['expected_surah_count'] ||
        ayahCount != metadata.single['expected_ayah_count']) {
      throw StateError('Quran Core declared counts do not match database');
    }
  }
}

final class QuranCoreStore {
  QuranCoreStore({required this.installer, DatabaseFactory? databaseFactory})
    : _databaseFactory = databaseFactory ?? databaseFactorySqflitePlugin;

  final QuranCoreInstaller installer;
  final DatabaseFactory _databaseFactory;
  Future<QuranRepository>? _initialization;
  Database? _database;

  Future<QuranRepository> initialize(QuranCoreArtifact artifact) =>
      _initialization ??= _open(artifact);

  Future<QuranRepository> _open(QuranCoreArtifact artifact) async {
    final file = await installer.install(artifact);
    final database = await _databaseFactory.openDatabase(
      file.path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: true),
    );
    try {
      await QuranCoreDatabaseVerifier.verify(database);
    } catch (_) {
      await database.close();
      rethrow;
    }
    _database = database;
    return SqfliteQuranRepository(database);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
    _initialization = null;
  }
}
