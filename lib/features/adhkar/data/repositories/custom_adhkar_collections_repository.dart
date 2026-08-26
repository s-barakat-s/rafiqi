import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/adhkar/domain/entities/custom_adhkar_collection.dart';

class CustomAdhkarCollectionsRepository {
  CustomAdhkarCollectionsRepository._();

  static final instance = CustomAdhkarCollectionsRepository._();
  static const _storageKey = 'adhkar.customCollections.v1';
  List<CustomAdhkarCollection>? _memory;

  Future<List<CustomAdhkarCollection>> load() async {
    final cached = _memory;
    if (cached != null) return List.unmodifiable(cached);
    final storage = await SharedPreferences.getInstance();
    final values = storage.getStringList(_storageKey) ?? const [];
    _memory = values
        .map(
          (value) => CustomAdhkarCollection.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          ),
        )
        .toList();
    return List.unmodifiable(_memory!);
  }

  Future<void> save(CustomAdhkarCollection collection) async {
    final collections = [...await load()];
    final index = collections.indexWhere((item) => item.id == collection.id);
    if (index < 0) {
      collections.add(collection);
    } else {
      collections[index] = collection;
    }
    _memory = collections;
    await _persist();
  }

  Future<void> delete(String collectionId) async {
    _memory = [...await load()]
      ..removeWhere((collection) => collection.id == collectionId);
    await _persist();
  }

  Future<void> _persist() async {
    final storage = await SharedPreferences.getInstance();
    await storage.setStringList(
      _storageKey,
      _memory!.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
