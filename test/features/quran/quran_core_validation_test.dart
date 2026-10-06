import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/features/quran/data/quran_core_dataset.dart';

void main() {
  late String fixture;
  setUpAll(
    () async => fixture = File(
      'test/features/quran/fixtures/synthetic_quran_core.json',
    ).readAsStringSync(),
  );

  QuranCoreDataset parse(Object source) {
    final text = source is String ? source : jsonEncode(source);
    return QuranCoreDataset.fromSourceJson(
      text,
      sourceChecksum: sha256.convert(utf8.encode(text)).toString(),
    );
  }

  test('accepts the explicitly synthetic complete fixture', () {
    expect(
      () => QuranCoreDatasetValidator.validate(parse(fixture)),
      returnsNormally,
    );
  });

  test('rejects duplicate and missing Ayah identity', () {
    final map = jsonDecode(fixture) as Map<String, dynamic>;
    final ayahs = map['ayahs'] as List<dynamic>;
    ayahs[1]['ayah_number'] = 1;
    expect(
      () => QuranCoreDatasetValidator.validate(parse(map)),
      throwsA(
        isA<QuranCoreValidationException>().having(
          (e) => e.issues.join(' '),
          'issues',
          allOf(contains('duplicate Ayah 1:1'), contains('missing Ayah 1:2')),
        ),
      ),
    );
  });

  test('rejects an invalid metadata relationship', () {
    final map = jsonDecode(fixture) as Map<String, dynamic>;
    (map['juz_boundaries'] as List<dynamic>).single['ayah_number'] = 99;
    expect(
      () => QuranCoreDatasetValidator.validate(parse(map)),
      throwsA(
        isA<QuranCoreValidationException>().having(
          (e) => e.issues.join(' '),
          'issues',
          contains('references missing 1:99'),
        ),
      ),
    );
  });

  test('requires provenance', () {
    final map = jsonDecode(fixture) as Map<String, dynamic>;
    (map['metadata'] as Map<String, dynamic>)['source_provider'] = '';
    expect(
      () => QuranCoreDatasetValidator.validate(parse(map)),
      throwsA(
        isA<QuranCoreValidationException>().having(
          (e) => e.issues,
          'issues',
          contains('source_provider is required'),
        ),
      ),
    );
  });
}
