import 'dart:convert';
import 'dart:io';

const _root = 'assets/data/adhkar';
const _outputRoot = '$_root/normalized';

void main() {
  Directory(_outputRoot).createSync(recursive: true);
  for (final category in ['morning', 'evening']) {
    final raw = _read(category);
    _write(category, raw.map((item) => _normalizeRegular(item)).toList());
  }
  _write('after_prayer', _normalizeAfterPrayer(_read('after_prayer')));
  _write('sleep', _normalizeSleep(_read('sleep')));
}

List<Map<String, dynamic>> _read(String category) =>
    (jsonDecode(File('$_root/$category.json').readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

void _write(String category, List<Map<String, dynamic>> entries) {
  final encoder = const JsonEncoder.withIndent('  ');
  File('$_outputRoot/$category.json').writeAsStringSync(
    '${encoder.convert(entries.map(_canonicalEntry).toList())}\n',
  );
}

Map<String, dynamic> _canonicalEntry(Map<String, dynamic> entry) {
  final type = entry['type'] as String;
  final isComposite = type == 'compositePractice';
  final repeatCount = isComposite
      ? entry['overallRepeatCount'] as int?
      : entry['repeatCount'] as int?;
  final instructionParts = <String>[
    if (_present(entry['instruction'])) entry['instruction'] as String,
    if (_present(entry['instructionAfter']))
      entry['instructionAfter'] as String,
  ];
  return {
    'id': entry['id'],
    'order': entry['displayOrder'] ?? entry['sourceOrder'],
    'category': entry['category'],
    'type': type,
    'text': entry['text'] == null
        ? null
        : _normalizeRecitation(
            entry['text'] as String,
            isQuran: _isQuran(entry['quran']),
          ),
    'repeatCount': repeatCount,
    'countDescription': repeatCount == null
        ? null
        : _countDescription(repeatCount),
    'instruction': instructionParts.isEmpty
        ? null
        : _normalizeNewlines(instructionParts.join('\n')),
    'appliesTo': entry['appliesTo'] ?? <String>[],
    'steps': ((entry['steps'] as List<dynamic>?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_canonicalStep)
        .toList(),
    'source': _canonicalSource(entry['source'] as Map<String, dynamic>?),
    'virtue': _canonicalVirtue(entry['virtue'] as Map<String, dynamic>?),
    'hadithText': _normalizedNullable(entry['hadithText']),
    'explanation': _normalizedNullable(entry['explanation']),
    'audioUrl': _normalizedNullable(entry['audioUrl']),
    'quran': _canonicalQuran(entry['quran'] as Map<String, dynamic>?),
  };
}

Map<String, dynamic> _canonicalStep(Map<String, dynamic> step) {
  final repeatCount = step['repeatCount'] as int;
  final quran = step['quran'] as Map<String, dynamic>?;
  return {
    'id': step['id'],
    'text': _normalizeRecitation(
      step['text'] as String,
      isQuran: _isQuran(quran),
    ),
    'repeatCount': repeatCount,
    'countDescription': _countDescription(repeatCount),
    'instruction': _normalizedNullable(step['instruction']),
    'quran': _canonicalQuran(quran),
  };
}

Map<String, dynamic> _canonicalSource(Map<String, dynamic>? source) => {
  'short': _normalizedNullable(source?['short']),
  'full': _normalizedNullable(source?['full']),
};

Map<String, dynamic> _canonicalVirtue(Map<String, dynamic>? virtue) => {
  'short': _normalizedNullable(virtue?['short'] ?? virtue?['preview']),
  'full': _normalizedNullable(virtue?['full']),
};

Map<String, dynamic> _canonicalQuran(Map<String, dynamic>? quran) {
  final isQuran = _isQuran(quran);
  final rawSurah = quran?['surah'] as String?;
  return {
    'isQuran': isQuran,
    'surah': rawSurah?.replaceFirst(RegExp(r'^سورة\s+'), ''),
    'ayahFrom': quran?['ayahFrom'],
    'ayahTo': quran?['ayahTo'],
  };
}

bool _isQuran(Map<String, dynamic>? quran) =>
    quran != null && (quran['surah'] != null || quran['isQuran'] == true);

String _normalizeRecitation(String value, {required bool isQuran}) {
  var normalized = _normalizeNewlines(value)
      .replaceAll('﴿', '')
      .replaceAll('﴾', '')
      .replaceAll('{', '')
      .replaceAll('}', '')
      .trim();
  if (isQuran) {
    normalized = normalized.replaceFirst(
      RegExp(r'\s*\.?\s*\[[^\]]+\]\s*$'),
      '',
    );
  }
  return normalized.trim();
}

String _normalizeNewlines(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

String? _normalizedNullable(Object? value) =>
    _present(value) ? _normalizeNewlines(value as String) : null;

String _countDescription(int count) => switch (count) {
  1 => 'مرة واحدة',
  3 => 'ثلاث مرات',
  4 => 'أربع مرات',
  7 => 'سبع مرات',
  10 => 'عشر مرات',
  33 => 'ثلاث وثلاثون مرة',
  34 => 'أربع وثلاثون مرة',
  100 => 'مائة مرة',
  _ => '$count مرات',
};

Map<String, dynamic> _normalizeRegular(Map<String, dynamic> raw) {
  final category = raw['category'] as String;
  final order = raw['order'] as int;
  final quran = _morningEveningQuran(category, order);
  final source = raw['source'] as String?;
  final virtue = raw['virtue'] as String?;
  return _withoutNulls({
    'id': raw['id'],
    'category': category,
    'sourceOrder': order,
    'displayOrder': order,
    'type': order == 1 ? 'prelude' : 'single',
    'text': raw['text'],
    'repeatCount': raw['repeatCount'],
    if (_present(raw['countDescription']))
      'countDescription': raw['countDescription'],
    if (_present(source)) 'source': _source(source!, quran: quran),
    if (_present(virtue)) 'virtue': _virtue(virtue!),
    'quran': ?quran,
    if (_present(raw['hadithText'])) 'hadithText': raw['hadithText'],
    if (_present(raw['explanation'])) 'explanation': raw['explanation'],
    if (_present(raw['audioUrl'])) 'audioUrl': raw['audioUrl'],
  });
}

List<Map<String, dynamic>> _normalizeAfterPrayer(
  List<Map<String, dynamic>> raw,
) {
  final result = <Map<String, dynamic>>[];
  for (final item in raw) {
    final order = item['order'] as int;
    final text = item['text'] as String;
    final source = item['source'] as String;
    if (order == 1) {
      final separator = text.indexOf(' (ثَلَاثًا)، ');
      final first = text.substring(0, separator);
      final second = text.substring(separator + ' (ثَلَاثًا)، '.length);
      result.add(
        _sequence(item, [
          _step('after-prayer-istighfar', first, 3),
          _step('after-prayer-salam', second, 1),
        ]),
      );
      continue;
    }
    if (order == 4) {
      final lines = text.split(RegExp(r'\r?\n'));
      final phrases = lines.first
          .replaceFirst(' (ثَلَاثًا وَثَلَاثِينَ مَرَّةً)', '')
          .split('، وَ');
      final conclusion = lines.last.replaceFirst(' (مَرَّةً وَاحِدَةً)', '');
      final quoted = RegExp(r'^"([^"]+)"(.*)$').firstMatch(source)!;
      result.add(
        _sequence(
          item,
          [
            _step('after-prayer-tasbeeh-subhanallah', phrases[0], 33),
            _step('after-prayer-tasbeeh-alhamdulillah', phrases[1], 33),
            _step('after-prayer-tasbeeh-allahu-akbar', phrases[2], 33),
            _step('after-prayer-tasbeeh-conclusion', conclusion, 1),
          ],
          sourceFull: quoted.group(2)!.trim(),
          virtueFull: quoted.group(1),
        ),
      );
      continue;
    }
    if (order == 5) {
      final surahs = text.split(RegExp(r'\r?\n\r?\n'));
      result.add(
        _sequence(item, [
          _step(
            'after-prayer-surah-al-ikhlas',
            surahs[0],
            1,
            quran: _quran('سورة الإخلاص'),
          ),
          _step(
            'after-prayer-surah-al-falaq',
            surahs[1],
            1,
            quran: _quran('سورة الفلق'),
          ),
          _step(
            'after-prayer-surah-an-nas',
            surahs[2],
            1,
            quran: _quran('سورة الناس'),
          ),
        ]),
      );
      continue;
    }
    if (order == 6) {
      const marker = ' . والنسائي';
      final splitAt = source.indexOf(marker);
      result.add(
        _single(
          item,
          sourceFull: splitAt < 0
              ? source
              : 'النسائي${source.substring(splitAt + marker.length)}',
          virtueFull: splitAt < 0 ? null : source.substring(0, splitAt),
        ),
      );
      continue;
    }
    if (order == 7 || order == 8) {
      final lines = text.split(RegExp(r'\r?\n'));
      result.add(
        _single(
          item,
          text: lines.first,
          appliesTo: order == 7 ? const ['fajr', 'maghrib'] : const ['fajr'],
          instruction: lines.skip(1).join('\n'),
        ),
      );
      continue;
    }
    result.add(_single(item));
  }
  return result;
}

List<Map<String, dynamic>> _normalizeSleep(List<Map<String, dynamic>> raw) {
  final result = <Map<String, dynamic>>[];
  for (var index = 0; index < raw.length; index++) {
    final item = raw[index];
    final order = item['order'] as int;
    final text = item['text'] as String;
    final source = item['source'] as String;
    if (order == 1) {
      final parts = text.split(RegExp(r'\r?\n\r?\n'));
      result.add(
        _withoutNulls({
          'id': item['id'],
          'category': 'sleep',
          'sourceOrder': order,
          'displayOrder': order,
          'type': 'compositePractice',
          'instruction': parts.first,
          'instructionAfter': parts.last,
          'overallRepeatCount': item['repeatCount'],
          'steps': [
            _step(
              'sleep-palms-al-ikhlas',
              parts[1],
              1,
              quran: _quran('سورة الإخلاص'),
            ),
            _step(
              'sleep-palms-al-falaq',
              parts[2],
              1,
              quran: _quran('سورة الفلق'),
            ),
            _step(
              'sleep-palms-an-nas',
              parts[3],
              1,
              quran: _quran('سورة الناس'),
            ),
          ],
          'source': _source(source),
        }),
      );
      continue;
    }
    if (order == 2) {
      final splitAt = source.indexOf('البخاري');
      result.add(
        _single(
          item,
          sourceFull: source.substring(splitAt),
          virtueFull: source.substring(0, splitAt).trim(),
        ),
      );
      continue;
    }
    if (order == 3) {
      final splitAt = source.indexOf('البخاري');
      result.add(
        _single(
          item,
          sourceFull: source.substring(splitAt),
          virtueFull: source
              .substring(0, splitAt)
              .replaceFirst(RegExp(r'،\s*$'), ''),
          quran: _quran('سورة البقرة', 285, 286),
        ),
      );
      continue;
    }
    if (order == 4 || order == 6) {
      final parts = source.split(RegExp(r'\r?\n\r?\n'));
      result.add(
        _single(
          item,
          instruction: parts.first.trim(),
          sourceFull: parts.skip(1).join('\n\n').trim(),
        ),
      );
      continue;
    }
    if (order == 8) {
      final grouped = raw.sublist(index, index + 3);
      final splitAt = source.indexOf('البخاري');
      result.add(
        _sequence(
          item,
          [
            _step(
              'sleep-tasbeeh-subhanallah',
              grouped[0]['text'] as String,
              grouped[0]['repeatCount'] as int,
            ),
            _step(
              'sleep-tasbeeh-alhamdulillah',
              grouped[1]['text'] as String,
              grouped[1]['repeatCount'] as int,
            ),
            _step(
              'sleep-tasbeeh-allahu-akbar',
              grouped[2]['text'] as String,
              grouped[2]['repeatCount'] as int,
            ),
          ],
          sourceFull: source.substring(splitAt),
          virtueFull: source.substring(0, splitAt).trim(),
        ),
      );
      index += 2;
      continue;
    }
    if (order == 15) {
      final instructionEnd = source.indexOf('قال صلى الله عليه وسلم');
      final citationStart = source.indexOf('البخاري');
      final evidence = source.substring(instructionEnd, citationStart).trim();
      const virtueText = 'فإن متَّ، متَّ على الفطرة';
      result.add(
        _single(
          item,
          instruction: source.substring(0, instructionEnd).trim(),
          sourceFull: source.substring(citationStart),
          virtueFull: virtueText,
          hadithText: evidence,
        ),
      );
      continue;
    }
    result.add(_single(item));
  }
  return result;
}

Map<String, dynamic> _single(
  Map<String, dynamic> raw, {
  String? text,
  String? instruction,
  List<String>? appliesTo,
  String? sourceFull,
  String? virtueFull,
  Map<String, dynamic>? quran,
  String? hadithText,
}) {
  final source = sourceFull ?? raw['source'] as String?;
  final virtue = virtueFull ?? raw['virtue'] as String?;
  return _withoutNulls({
    'id': raw['id'],
    'category': raw['category'],
    'sourceOrder': raw['order'],
    'displayOrder': raw['order'],
    'type': 'single',
    'text': text ?? raw['text'],
    'repeatCount': raw['repeatCount'],
    if (_present(raw['countDescription']))
      'countDescription': raw['countDescription'],
    if (_present(instruction)) 'instruction': instruction,
    if (appliesTo != null && appliesTo.isNotEmpty) 'appliesTo': appliesTo,
    if (_present(source)) 'source': _source(source!, quran: quran),
    if (_present(virtue)) 'virtue': _virtue(virtue!),
    'quran': ?quran,
    if (_present(hadithText ?? raw['hadithText']))
      'hadithText': hadithText ?? raw['hadithText'],
    if (_present(raw['explanation'])) 'explanation': raw['explanation'],
    if (_present(raw['audioUrl'])) 'audioUrl': raw['audioUrl'],
  });
}

Map<String, dynamic> _sequence(
  Map<String, dynamic> raw,
  List<Map<String, dynamic>> steps, {
  String? sourceFull,
  String? virtueFull,
}) {
  final source = sourceFull ?? raw['source'] as String?;
  final virtue = virtueFull ?? raw['virtue'] as String?;
  return _withoutNulls({
    'id': raw['id'],
    'category': raw['category'],
    'sourceOrder': raw['order'],
    'displayOrder': raw['order'],
    'type': 'sequence',
    'steps': steps,
    if (_present(source)) 'source': _source(source!),
    if (_present(virtue)) 'virtue': _virtue(virtue!),
    if (_present(raw['hadithText'])) 'hadithText': raw['hadithText'],
    if (_present(raw['explanation'])) 'explanation': raw['explanation'],
    if (_present(raw['audioUrl'])) 'audioUrl': raw['audioUrl'],
  });
}

Map<String, dynamic> _step(
  String id,
  String text,
  int repeatCount, {
  Map<String, dynamic>? quran,
}) => _withoutNulls({
  'id': id,
  'text': text.trim(),
  'repeatCount': repeatCount,
  'quran': ?quran,
});

Map<String, dynamic>? _morningEveningQuran(String category, int order) {
  if (category != 'morning' && category != 'evening') return null;
  return switch (order) {
    2 => _quran('سورة البقرة', 255, 255),
    3 => _quran('سورة البقرة', 285, 286),
    4 => _quran('سورة الإخلاص'),
    5 => _quran('سورة الفلق'),
    6 => _quran('سورة الناس'),
    _ => null,
  };
}

Map<String, dynamic> _quran(String surah, [int? from, int? to]) =>
    _withoutNulls({'surah': surah, 'ayahFrom': from, 'ayahTo': to});

Map<String, dynamic> _source(String full, {Map<String, dynamic>? quran}) => {
  'short': _shortSource(full, quran: quran),
  'full': full.trim(),
};

String _shortSource(String full, {Map<String, dynamic>? quran}) {
  if (quran != null) {
    final surah = quran['surah'] as String;
    final from = quran['ayahFrom'] as int?;
    final to = quran['ayahTo'] as int?;
    if (from == null) return surah;
    return to != null && to != from
        ? '$surah: ${_arabicDigits(from)}–${_arabicDigits(to)}'
        : '$surah: ${_arabicDigits(from)}';
  }
  final hasBukhari = full.contains('البخاري');
  final hasMuslim = full.contains('مسلم');
  final hasAbuDawud = full.contains('أبو داود');
  final hasTirmidhi = full.contains('الترمذي') || full.contains('التّرمذي');
  if (hasBukhari && hasMuslim) return 'رواه البخاري ومسلم';
  if (hasAbuDawud && hasTirmidhi) return 'رواه أبو داود والترمذي';
  if (hasBukhari) return 'رواه البخاري';
  if (hasMuslim) return 'رواه مسلم';
  if (hasAbuDawud) return 'رواه أبو داود';
  if (hasTirmidhi) return 'رواه الترمذي';
  if (full.contains('النسائي')) return 'رواه النسائي';
  if (full.contains('ابن ماجه')) return 'رواه ابن ماجه';
  if (full.contains('أحمد')) return 'رواه أحمد';
  return full.trim().length <= 64 ? full.trim() : 'المرجع محفوظ في التفاصيل';
}

String _arabicDigits(int value) => value.toString().replaceAllMapped(
  RegExp(r'\d'),
  (match) => '٠١٢٣٤٥٦٧٨٩'[int.parse(match.group(0)!)],
);

Map<String, dynamic> _virtue(String full) => {
  'preview': _virtuePreview(full),
  'full': full.trim(),
};

String _virtuePreview(String full) {
  var value = full.trim().replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '');
  if (value.length <= 150) return value;
  final shortened = value.substring(0, 150);
  final endings = RegExp(r'[.!؟؛]').allMatches(shortened).toList();
  if (endings.isNotEmpty && endings.last.end >= 70) {
    return shortened.substring(0, endings.last.end).trim();
  }
  return '${shortened.trimRight()}…';
}

bool _present(Object? value) => value is String && value.trim().isNotEmpty;

Map<String, dynamic> _withoutNulls(Map<String, dynamic> value) =>
    Map.fromEntries(value.entries.where((entry) => entry.value != null));
