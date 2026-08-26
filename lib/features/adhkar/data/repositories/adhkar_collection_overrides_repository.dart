import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_collection_overrides.dart';

class AdhkarCollectionOverridesRepository {
  AdhkarCollectionOverridesRepository._();

  static final instance = AdhkarCollectionOverridesRepository._();
  static const _keyPrefix = 'adhkar.collectionOverrides.';
  final Map<String, AdhkarCollectionOverrides> _memory = {};
  Future<void> _pendingWrite = Future.value();

  Future<AdhkarCollectionOverrides> load(String collectionId) async {
    final cached = _memory[collectionId];
    if (cached != null) return cached;
    final storage = await SharedPreferences.getInstance();
    final encoded = storage.getString('$_keyPrefix$collectionId');
    if (encoded == null) {
      return _memory[collectionId] = const AdhkarCollectionOverrides();
    }
    try {
      return _memory[collectionId] = AdhkarCollectionOverrides.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
    } on Object {
      return _memory[collectionId] = const AdhkarCollectionOverrides();
    }
  }

  Future<void> save(
    String collectionId,
    AdhkarCollectionOverrides overrides,
  ) async {
    _memory[collectionId] = overrides;
    _pendingWrite = _pendingWrite.then((_) async {
      final storage = await SharedPreferences.getInstance();
      if (overrides.isEmpty) {
        await storage.remove('$_keyPrefix$collectionId');
      } else {
        await storage.setString(
          '$_keyPrefix$collectionId',
          jsonEncode(overrides.toJson()),
        );
      }
    });
    await _pendingWrite;
  }

  Future<void> clear(String collectionId) async {
    const empty = AdhkarCollectionOverrides();
    _memory[collectionId] = empty;
    await save(collectionId, empty);
  }
}
