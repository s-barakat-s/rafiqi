import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/quran/domain/annotations/quran_annotation.dart';

final class QuranAnnotationStore {
  static const maximumAnnotationsPerEdition = 500;
  static const _storageKey = 'quran.annotations.qpc_v4_research.v1';

  Future<List<QuranAnnotation>> load() async {
    final storage = await SharedPreferences.getInstance();
    final encoded = storage.getString(_storageKey);
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List<Object?>) return const [];
      final annotations = <QuranAnnotation>[];
      for (final entry in decoded) {
        try {
          if (entry is! Map<Object?, Object?>) continue;
          annotations.add(
            QuranAnnotation.fromJson(
              entry.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        } on Object {
          // Ignore only the incompatible record; valid local annotations remain.
        }
      }
      annotations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return List.unmodifiable(annotations);
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<QuranAnnotation> annotations) async {
    if (annotations.length > maximumAnnotationsPerEdition) {
      throw StateError('Quran annotation limit exceeded');
    }
    final storage = await SharedPreferences.getInstance();
    final encoded = jsonEncode([
      for (final annotation in annotations) annotation.toJson(),
    ]);
    final persisted = await storage.setString(_storageKey, encoded);
    if (!persisted) throw StateError('Quran annotations were not persisted');
  }
}
