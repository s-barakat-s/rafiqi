import 'dart:convert';
import 'dart:io';

enum EvidenceState { measured, inferred, pending }

final class RendererCandidateEvidence {
  const RendererCandidateEvidence({
    required this.id,
    required this.sourceReference,
    required this.sourceVersion,
    required this.licenseStatus,
    required this.productionEligible,
    required this.authenticFidelityState,
    required this.sizeState,
    required this.performanceState,
    required this.androidState,
    required this.iosState,
    required this.measurements,
  });

  final String id;
  final String sourceReference;
  final String sourceVersion;
  final String licenseStatus;
  final bool productionEligible;
  final EvidenceState authenticFidelityState;
  final EvidenceState sizeState;
  final EvidenceState performanceState;
  final EvidenceState androidState;
  final EvidenceState iosState;
  final Map<String, num> measurements;

  bool get decisionEligible =>
      productionEligible &&
      authenticFidelityState == EvidenceState.measured &&
      sizeState == EvidenceState.measured &&
      performanceState == EvidenceState.measured &&
      androidState == EvidenceState.measured &&
      iosState == EvidenceState.measured;
}

final class RendererBakeoffResult {
  const RendererBakeoffResult({
    required this.candidates,
    required this.selectedRenderer,
  });
  final List<RendererCandidateEvidence> candidates;
  final String? selectedRenderer;
  bool get decisionPending => selectedRenderer == null;
}

RendererBakeoffResult evaluateRendererBakeoff(String jsonSource) {
  final root = jsonDecode(jsonSource) as Map<String, dynamic>;
  final candidates = (root['candidates'] as List<dynamic>)
      .map((value) {
        final row = value as Map<String, dynamic>;
        EvidenceState state(String key) =>
            EvidenceState.values.byName(row[key] as String);
        return RendererCandidateEvidence(
          id: row['id'] as String,
          sourceReference: row['source_reference'] as String,
          sourceVersion: row['source_version'] as String,
          licenseStatus: row['license_status'] as String,
          productionEligible: row['production_eligible'] as bool,
          authenticFidelityState: state('authentic_fidelity_state'),
          sizeState: state('size_state'),
          performanceState: state('performance_state'),
          androidState: state('android_state'),
          iosState: state('ios_state'),
          measurements: (row['measurements'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as num),
          ),
        );
      })
      .toList(growable: false);
  final ids = candidates.map((value) => value.id).toSet();
  if (!ids.containsAll({
        'semanticVector',
        'digitalKhatt',
        'qcfV2',
        'pageAsset',
      }) ||
      ids.length != 4) {
    throw StateError(
      'Bake-off must contain exactly semantic vector, DigitalKhatt, QCF V2, and page asset candidates',
    );
  }
  final requested = root['selected_renderer'] as String?;
  if (requested != null) {
    final selected = candidates
        .where((value) => value.id == requested)
        .firstOrNull;
    if (selected == null || !selected.decisionEligible) {
      throw StateError(
        'A renderer cannot be selected without complete measured evidence and production approval',
      );
    }
  }
  return RendererBakeoffResult(
    candidates: candidates,
    selectedRenderer: requested,
  );
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/quran/benchmark/renderer_bakeoff.dart <evidence.json>',
    );
    exitCode = 64;
    return;
  }
  final result = evaluateRendererBakeoff(
    await File(arguments.single).readAsString(),
  );
  for (final candidate in result.candidates) {
    stdout.writeln(
      '${candidate.id}: productionEligible=${candidate.productionEligible}, fidelity=${candidate.authenticFidelityState.name}, size=${candidate.sizeState.name}, performance=${candidate.performanceState.name}, android=${candidate.androidState.name}, ios=${candidate.iosState.name}',
    );
  }
  stdout.writeln(
    result.decisionPending
        ? 'rendererDecision=pending'
        : 'rendererDecision=${result.selectedRenderer}',
  );
}
