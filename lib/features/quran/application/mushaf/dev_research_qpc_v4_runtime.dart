import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/features/quran/application/mushaf/qpc_v4_tajweed_pack_source.dart';
import 'package:tasbeh/features/quran/domain/mushaf/qpc_v4_tajweed_pack.dart';

/// RESEARCH ONLY — never opens the unapproved QPC pack outside debug mode.
final class DevResearchQpcV4Runtime {
  const DevResearchQpcV4Runtime._({
    required this.source,
    required this.manifest,
  });

  final QpcV4TajweedPackSource source;
  final QpcV4TajweedManifest manifest;

  static Future<DevResearchQpcV4Runtime> open({
    AssetBundle? assetBundle,
    Directory? projectRoot,
  }) async {
    if (!kDebugMode) {
      throw StateError('Research-only QPC runtime is disabled outside debug');
    }
    final source = DevQpcV4TajweedPackSource(
      assetBundle: assetBundle,
      projectRoot: projectRoot,
    );
    final manifest = await source.loadManifest();
    return DevResearchQpcV4Runtime._(source: source, manifest: manifest);
  }

  Future<void> close() async {}
}
