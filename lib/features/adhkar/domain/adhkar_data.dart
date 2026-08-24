import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DhikrEntryType { prelude, single, sequenceStep, compositeStep }

class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.order,
    required this.category,
    required this.text,
    required this.repeatCount,
    required this.entryType,
    this.parentId,
    this.countDescription,
    this.instruction,
    this.appliesTo = const [],
    this.source,
    this.fullSource,
    this.virtue,
    this.virtuePreview,
    this.hadithText,
    this.explanation,
    this.audioUrl,
    this.isQuran,
    this.surah,
    this.ayahFrom,
    this.ayahTo,
  });

  final String id;
  final int order;
  final String category;
  final String text;
  final int repeatCount;
  final DhikrEntryType entryType;
  final String? parentId;
  final String? countDescription;
  final String? instruction;
  final List<String> appliesTo;
  final String? source;
  final String? fullSource;
  final String? virtue;
  final String? virtuePreview;
  final String? hadithText;
  final String? explanation;
  final String? audioUrl;
  final bool? isQuran;
  final String? surah;
  final int? ayahFrom;
  final int? ayahTo;

  bool get isPrelude => entryType == DhikrEntryType.prelude;
}

class AdhkarCategory {
  const AdhkarCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<DhikrItem> items;
}

abstract final class AdhkarLocalRepository {
  static Future<List<AdhkarCategory>>? _cache;

  static Future<List<AdhkarCategory>> loadCategories() =>
      _cache ??= _loadCategories();

  static Future<List<AdhkarCategory>> _loadCategories() async {
    final definitions = [
      (
        'morning',
        'أذكار الصباح',
        'بداية مطمئنة ليومك وحفظٌ بإذن الله',
        Icons.wb_sunny_outlined,
      ),
      (
        'evening',
        'أذكار المساء',
        'سكينة المساء وخاتمة هادئة لليوم',
        Icons.nightlight_outlined,
      ),
      (
        'after_prayer',
        'أذكار بعد الصلاة',
        'ورد مأثور تتمّ به الفريضة',
        Icons.mosque_outlined,
      ),
      (
        'sleep',
        'أذكار النوم',
        'طمأنينة القلب قبل النوم',
        Icons.bedtime_outlined,
      ),
    ];
    return Future.wait(
      definitions.map((definition) async {
        final raw = await rootBundle.loadString(
          'assets/data/adhkar/normalized/${definition.$1}.json',
        );
        final entries = (jsonDecode(raw) as List<dynamic>)
            .cast<Map<String, dynamic>>()
          ..sort(
            (a, b) =>
                (a['order'] as int).compareTo(b['order'] as int),
          );
        final items = entries.expand(_expandEntry).toList(growable: false);
        return AdhkarCategory(
          id: definition.$1,
          title: definition.$2,
          subtitle: definition.$3,
          icon: definition.$4,
          items: List.unmodifiable(items),
        );
      }),
    );
  }

  static Iterable<DhikrItem> _expandEntry(Map<String, dynamic> entry) sync* {
    final type = entry['type'] as String;
    final parentId = entry['id'] as String;
    final displayOrder = entry['order'] as int;
    if (type == 'prelude' || type == 'single') {
      yield _item(
        entry: entry,
        content: entry,
        id: parentId,
        order: displayOrder * 100,
        entryType: type == 'prelude'
            ? DhikrEntryType.prelude
            : DhikrEntryType.single,
      );
      return;
    }

    final steps = (entry['steps'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    if (type == 'sequence') {
      for (var stepIndex = 0; stepIndex < steps.length; stepIndex++) {
        final step = steps[stepIndex];
        yield _item(
          entry: entry,
          content: step,
          id: step['id'] as String,
          parentId: parentId,
          order: displayOrder * 100 + stepIndex,
          entryType: DhikrEntryType.sequenceStep,
        );
      }
      return;
    }

    if (type == 'compositePractice') {
      final cycles = entry['repeatCount'] as int;
      for (var cycle = 0; cycle < cycles; cycle++) {
        for (var stepIndex = 0; stepIndex < steps.length; stepIndex++) {
          final step = steps[stepIndex];
          yield _item(
            entry: entry,
            content: step,
            id: '${step['id']}-cycle-${cycle + 1}',
            parentId: parentId,
            order: displayOrder * 100 + cycle * steps.length + stepIndex,
            entryType: DhikrEntryType.compositeStep,
            inheritEntryInstructions: false,
            instruction: stepIndex == 0
                ? entry['instruction'] as String?
                : null,
          );
        }
      }
      return;
    }

    throw FormatException('Unsupported adhkar entry type: $type');
  }

  static DhikrItem _item({
    required Map<String, dynamic> entry,
    required Map<String, dynamic> content,
    required String id,
    required int order,
    required DhikrEntryType entryType,
    String? parentId,
    String? instruction,
    bool inheritEntryInstructions = true,
  }) {
    final source = entry['source'] as Map<String, dynamic>?;
    final virtue = entry['virtue'] as Map<String, dynamic>?;
    final contentQuran = content['quran'] as Map<String, dynamic>?;
    final entryQuran = entry['quran'] as Map<String, dynamic>;
    final quran = contentQuran?['isQuran'] == true ? contentQuran! : entryQuran;
    final isQuran = quran['isQuran'] as bool;
    return DhikrItem(
      id: id,
      order: order,
      category: entry['category'] as String,
      text: content['text'] as String,
      repeatCount: content['repeatCount'] as int,
      entryType: entryType,
      parentId: parentId,
      countDescription:
          (content['countDescription'] ?? entry['countDescription']) as String?,
      instruction: instruction ??
          (inheritEntryInstructions ? entry['instruction'] as String? : null),
      appliesTo: ((entry['appliesTo'] as List<dynamic>?) ?? const [])
          .cast<String>(),
      source: source?['short'] as String?,
      fullSource: source?['full'] as String?,
      virtue: virtue?['full'] as String?,
      virtuePreview: virtue?['short'] as String?,
      hadithText: entry['hadithText'] as String?,
      explanation: entry['explanation'] as String?,
      audioUrl: entry['audioUrl'] as String?,
      isQuran: isQuran,
      surah: quran['surah'] as String?,
      ayahFrom: quran['ayahFrom'] as int?,
      ayahTo: quran['ayahTo'] as int?,
    );
  }
}
