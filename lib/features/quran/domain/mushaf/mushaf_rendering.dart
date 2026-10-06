import 'package:meta/meta.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/resource_provenance.dart';

@immutable
final class MushafNormalizedPoint {
  MushafNormalizedPoint(this.x, this.y) {
    if (x < 0 || x > 1 || y < 0 || y > 1) {
      throw ArgumentError('Normalized point must be inside the unit square');
    }
  }

  final double x;
  final double y;
}

@immutable
final class MushafNormalizedRect {
  MushafNormalizedRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  }) {
    if (left < 0 || top < 0 || right > 1 || bottom > 1) {
      throw ArgumentError('Normalized region must be inside the unit square');
    }
    if (left >= right || top >= bottom) {
      throw ArgumentError('Normalized region must have positive area');
    }
  }

  final double left;
  final double top;
  final double right;
  final double bottom;

  bool contains(MushafNormalizedPoint point) =>
      point.x >= left &&
      point.x <= right &&
      point.y >= top &&
      point.y <= bottom;
}

@immutable
final class MushafRenderWord {
  MushafRenderWord({
    required this.wordKey,
    required this.rendererToken,
    this.regions = const [],
  }) {
    if (rendererToken.trim().isEmpty) {
      throw ArgumentError('Renderer token is required');
    }
  }

  final WordKey wordKey;

  /// Renderer-owned data. It is never a canonical Quran identity.
  final String rendererToken;
  final List<MushafNormalizedRect> regions;
}

@immutable
final class MushafRendererPage {
  const MushafRendererPage({required this.pageKey, required this.words});

  final MushafPageKey pageKey;
  final List<MushafRenderWord> words;
}

@immutable
final class MushafRenderRequest {
  const MushafRenderRequest({
    required this.edition,
    required this.page,
    required this.lines,
    required this.placements,
  });

  final MushafEdition edition;
  final MushafPage page;
  final List<MushafLine> lines;
  final List<MushafWordPlacement> placements;
}

abstract interface class MushafRendererAdapter {
  MushafRenderStrategy get strategy;
  List<QuranResourceProvenance> get resources;

  Future<void> initialize(MushafEdition edition);
  Future<MushafRendererPage> preparePage(MushafRenderRequest request);
}

abstract final class MushafRendererActivationValidator {
  static void validate({
    required MushafEdition edition,
    required MushafRendererAdapter renderer,
    required bool forProduction,
  }) {
    final issues = <String>[];
    if (renderer.strategy != edition.renderStrategy) {
      issues.add(
        'Renderer ${renderer.strategy.name} does not match edition '
        '${edition.renderStrategy.name}',
      );
    }

    issues.addAll(edition.provenance.validate(forProduction: forProduction));
    if (!forProduction && !edition.provenance.researchEligible) {
      issues.add('Mushaf layout resource is rejected');
    }
    final resourcesById = <String, QuranResourceProvenance>{};
    for (final resource in renderer.resources) {
      if (resourcesById.containsKey(resource.resourceId)) {
        issues.add('Duplicate renderer resource ${resource.resourceId}');
      }
      resourcesById[resource.resourceId] = resource;
      issues.addAll(resource.validate(forProduction: forProduction));
      if (!forProduction && !resource.researchEligible) {
        issues.add('Renderer resource ${resource.resourceId} is rejected');
      }
      if (!resource.compatibility.riwayahIds.contains(
        edition.riwayahId.value,
      )) {
        issues.add(
          'Renderer resource ${resource.resourceId} has wrong Riwayah',
        );
      }
      if (!resource.compatibility.mushafEditionIds.contains(edition.id.value)) {
        issues.add(
          'Renderer resource ${resource.resourceId} has wrong edition',
        );
      }
    }

    final requiredIds = <String>{
      edition.scriptResourceId,
      ?edition.fontResourceId,
    };
    for (final id in requiredIds) {
      if (!resourcesById.containsKey(id)) {
        issues.add('Required renderer resource $id is missing');
      }
    }
    if (issues.isNotEmpty) {
      throw MushafRendererActivationException(List.unmodifiable(issues));
    }
  }
}

final class MushafRendererActivationException implements Exception {
  const MushafRendererActivationException(this.issues);

  final List<String> issues;

  @override
  String toString() =>
      'Mushaf renderer activation failed:\n${issues.join('\n')}';
}
