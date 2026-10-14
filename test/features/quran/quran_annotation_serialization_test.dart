import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/features/quran/domain/annotations/quran_annotation.dart';

void main() {
  test('Quran annotation preserves semantic range and metadata', () {
    final createdAt = DateTime.utc(2026, 10, 14, 9, 30);
    final annotation = QuranAnnotation(
      id: 'qra-test',
      editionId: qpcV4ResearchAnnotationEditionId,
      granularity: QuranAnnotationGranularity.word,
      startIdentity: '2:3:4',
      endIdentity: '2:5:6',
      colorId: QuranHighlightColorId.purple,
      comment: 'تعليق خاص',
      createdAt: createdAt,
      lastModifiedAt: createdAt,
    );

    final restored = QuranAnnotation.fromJson(annotation.toJson());

    expect(restored.id, annotation.id);
    expect(restored.editionId, qpcV4ResearchAnnotationEditionId);
    expect(restored.granularity, QuranAnnotationGranularity.word);
    expect(restored.startIdentity, '2:3:4');
    expect(restored.endIdentity, '2:5:6');
    expect(restored.colorId, QuranHighlightColorId.purple);
    expect(restored.comment, 'تعليق خاص');
    expect(restored.createdAt, createdAt);
    expect(restored.lastModifiedAt, createdAt);
    expect(
      () => QuranAnnotation.fromJson({
        ...annotation.toJson(),
        'edition_id': 'unsupported-edition',
      }),
      throwsFormatException,
    );
  });
}
